-- DROP FUNCTION epg_stats.get_series_statio_all_indexes_hist(int8, interval);

CREATE OR REPLACE FUNCTION epg_stats.get_series_statio_all_indexes_hist(g_ts bigint, g_interval interval)
 RETURNS TABLE(begin_ts bigint, end_ts bigint, relid oid, indexrelid oid, schemaname character varying, relname character varying, indexrelname character varying, idx_blks_read bigint, idx_blks_hit bigint)
 LANGUAGE plpgsql
AS $function$
declare 
  c1 REFCURSOR;
  row_data RECORD;
begin
	CREATE TEMP TABLE IF NOT EXISTS temp_get_series_statio_all_indexes_hist_results (
		begin_ts bigint, 
		end_ts bigint, 
		relid oid, 
		indexrelid oid, 
		schemaname character varying, 
		relname character varying, 
		indexrelname character varying, 
		idx_blks_read bigint, 
		idx_blks_hit bigint
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
      insert into temp_get_series_statio_all_indexes_hist_results
	    select 
	      min(saih.ts) AS begin_ts, 
	      max(saih.ts) AS end_ts, 
	      saih.relid, saih.indexrelid, saih.schemaname, saih.relname, saih.indexrelname,
	      abs(max(saih.idx_blks_read) - coalesce(min(saih.idx_blks_read),0)) as idx_blks_read,
	      abs(max(saih.idx_blks_hit) - coalesce(min(saih.idx_blks_hit),0)) as idx_blks_hit
	    from 
	      epg_stats.statio_all_indexes_hist  saih
		where saih.ts in (row_data.current_snapshot, row_data.previous_snapshot)
	    group by saih.relid, saih.indexrelid, saih.schemaname, saih.relname, saih.indexrelname ;
    END LOOP;
    CLOSE c1;

	return query
	  select * from temp_get_series_statio_all_indexes_hist_results;

	drop table if exists temp_get_series_statio_all_indexes_hist_results;
end;
$function$
;
