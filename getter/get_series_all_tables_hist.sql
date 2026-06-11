-- DROP FUNCTION epg_stats.get_series_all_tables_hist(int8, interval);

CREATE OR REPLACE FUNCTION epg_stats.get_series_all_tables_hist(g_ts bigint, g_interval interval)
 RETURNS TABLE(begin_ts bigint, end_ts bigint, relid oid, schemaname character varying, relname character varying, seq_scan bigint, seq_tup_read bigint, idx_scan bigint, idx_tup_fetch bigint, n_tup_ins bigint, n_tup_upd bigint, n_tup_del bigint, n_tup_hot_upd bigint, n_live_tup bigint, n_dead_tup bigint, n_mod_since_analyze bigint, last_vacuum timestamp with time zone, last_autovacuum timestamp with time zone, last_analyze timestamp with time zone, last_autoanalyze timestamp with time zone, vacuum_count bigint, autovacuum_count bigint, analyze_count bigint, autoanalyze_count bigint)
 LANGUAGE plpgsql
AS $function$
declare 
  c1 REFCURSOR;
  row_data RECORD;
begin
	CREATE TEMP TABLE IF NOT EXISTS temp_get_series_all_tables_hist_results (
		begin_ts bigint, 
    	end_ts bigint, 
		relid oid, 
		schemaname character varying, 
		relname character varying, 
		seq_scan bigint, 
		seq_tup_read bigint, 
		idx_scan bigint, 
		idx_tup_fetch bigint, 
		n_tup_ins bigint, 
		n_tup_upd bigint, 
		n_tup_del bigint, 
		n_tup_hot_upd bigint, 
		n_live_tup bigint, 
		n_dead_tup bigint, 
		n_mod_since_analyze bigint, 
		last_vacuum timestamp with time zone, 
		last_autovacuum timestamp with time zone, 
		last_analyze timestamp with time zone, 
		last_autoanalyze timestamp with time zone, 
		vacuum_count bigint, 
		autovacuum_count bigint, 
		analyze_count bigint, 
		autoanalyze_count bigint
	) ON COMMIT DROP;

  open c1 for
	select
		to_timestamp(current_snapshot),
		to_timestamp(previous_snapshot),
		current_snapshot,
		previous_snapshot,
		(date_trunc('minute', to_timestamp(current_snapshot))-date_trunc('minute',to_timestamp(previous_snapshot)))::interval as iinterval
	from
		(
		select
			ts_timestamp,
			ts_epoch as current_snapshot,
			lag(ts_epoch) over (
			order by ts_epoch) as previous_snapshot
		from
			epg_stats.find_interval_snapshots(g_ts, g_interval )
		order by
			1 desc
		)t
	where
		previous_snapshot is not null;

    LOOP
      FETCH c1 INTO row_data;
      EXIT WHEN NOT FOUND;
      -- raise notice '%', row_data.ts_timestamp;
      insert into temp_get_series_all_tables_hist_results
	    select 
	      min(sath.ts) AS ts, max(sath.ts) AS ts, sath.relid, sath.schemaname, sath.relname, 
	      abs(max(sath.seq_scan) -  coalesce(min(sath.seq_scan),0)) as seq_scan,
	      abs(max(sath.seq_tup_read) - coalesce(min(sath.seq_tup_read),0))  as seq_tup_read,
	      abs(max(sath.idx_scan) - coalesce(min(sath.idx_scan),0)) as idx_scan,
	      abs(max(sath.idx_tup_fetch) - coalesce(min(sath.idx_tup_fetch),0)) as idx_tup_fetch,
	      abs(max(sath.n_tup_ins) - coalesce(min(sath.n_tup_ins),0)) as n_tup_ins,
	      abs(max(sath.n_tup_upd) - coalesce(min(sath.n_tup_upd),0)) as n_tup_upd,
	      abs(max(sath.n_tup_del) - coalesce(min(sath.n_tup_del),0)) as n_tup_del,
	      abs(max(sath.n_tup_hot_upd) - coalesce(min(sath.n_tup_hot_upd),0)) as n_tup_hot_upd,
	      max(sath.n_live_tup) n_live_tup,
	      max(sath.n_dead_tup) n_dead_tup,
	      max(sath.n_mod_since_analyze) as n_mod_since_analyze,
	      max(sath.last_vacuum) as last_vacuum,
	      max(sath.last_autovacuum) as last_autovacuum,
	      max(sath.last_analyze) as last_analyze,
	      max(sath.last_autoanalyze) as last_autoanalyze,
	      max(sath.vacuum_count) as vacuum_count,
	      max(sath.autovacuum_count) as autovacuum_count,
	      max(sath.analyze_count) as analyze_count,
	      max(sath.autoanalyze_count) as autoanalyze_count
	    from 
	      epg_stats.stat_all_tables_hist  sath
	    WHERE sath.ts IN (row_data.current_snapshot, row_data.previous_snapshot) 
	    group by sath.relid, sath.schemaname, sath.relname;
    END LOOP;
    CLOSE c1;

	return query
	select * from temp_get_series_all_tables_hist_results;

	drop table if exists temp_get_series_all_tables_hist_results;
end;
$function$
;
