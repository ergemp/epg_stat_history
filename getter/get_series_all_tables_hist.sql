-- DROP FUNCTION epg_stats.get_series_all_tables_hist(int8, interval);

CREATE OR REPLACE FUNCTION epg_stats.get_series_all_tables_hist(g_ts bigint, g_interval interval)
 RETURNS TABLE(begin_ts bigint, end_ts bigint, relid oid, schemaname character varying, relname character varying, seq_scan bigint, seq_tup_read bigint, idx_scan bigint, idx_tup_fetch bigint, n_tup_ins bigint, n_tup_upd bigint, n_tup_del bigint, n_tup_hot_upd bigint, n_live_tup bigint, n_dead_tup bigint, n_mod_since_analyze bigint, last_vacuum timestamp with time zone, last_autovacuum timestamp with time zone, last_analyze timestamp with time zone, last_autoanalyze timestamp with time zone, vacuum_count bigint, autovacuum_count bigint, analyze_count bigint, autoanalyze_count bigint)
 LANGUAGE plpgsql
AS $function$
declare 
  c1 REFCURSOR;
  row_data RECORD;
begin
	CREATE TEMP TABLE IF NOT EXISTS temp_results (
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
	  ts_timestamp,
	  ts_epoch as current_snapshot,
	  lag(ts_epoch) OVER (ORDER BY ts_epoch) AS previous_snapshot
	from epg_stats.find_interval_snapshots(g_ts, g_interval) order by 1 desc;

    LOOP
      FETCH c1 INTO row_data;
      EXIT WHEN NOT FOUND;
      -- raise notice '%', row_data.ts_timestamp;
      insert into temp_results
        select * from epg_stats.get_stat_all_tables_hist(row_data.current_snapshot, (to_timestamp(row_data.current_snapshot)-to_timestamp(row_data.previous_snapshot))::interval);    
    END LOOP;
    CLOSE c1;

	return query
	select * from temp_results;
end;
$function$
;
