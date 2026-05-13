-- DROP FUNCTION epg_stats.get_series_statio_all_tables_hist(int8, interval);

CREATE OR REPLACE FUNCTION epg_stats.get_series_statio_all_tables_hist(g_ts bigint, g_interval interval)
 RETURNS TABLE(begin_ts bigint, end_ts bigint, relid oid, schemaname character varying, relname character varying, heap_blks_read bigint, heap_blks_hit bigint, idx_blks_read bigint, idx_blks_hit bigint, toast_blks_read bigint, toast_blks_hit bigint, tidx_blks_read bigint, tidx_blks_hit bigint)
 LANGUAGE plpgsql
AS $function$
declare 
  c1 REFCURSOR;
  row_data RECORD;
begin
	CREATE TEMP TABLE IF NOT EXISTS temp_results_get_series_statio_all_tables_hist (
		begin_ts bigint, 
		end_ts bigint, 
		relid oid, 
		schemaname character varying, 
		relname character varying, 
		heap_blks_read bigint, 
		heap_blks_hit bigint, 
		idx_blks_read bigint, 
		idx_blks_hit bigint, 
		toast_blks_read bigint, 
		toast_blks_hit bigint, 
		tidx_blks_read bigint, 
		tidx_blks_hit bigint
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
      insert into temp_results_get_series_statio_all_tables_hist
        select * from epg_stats.get_statio_all_tables_hist(row_data.current_snapshot, (to_timestamp(row_data.current_snapshot)-to_timestamp(row_data.previous_snapshot))::interval);    
    END LOOP;
    CLOSE c1;

	return query
	select * from temp_results_get_series_statio_all_tables_hist;
	
	DROP TABLE IF EXISTS temp_results_get_series_statio_all_tables_hist;
end;
$function$
;