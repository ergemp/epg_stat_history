-- DROP FUNCTION epg_stats.get_series_statio_all_tables_hist(int8, interval);

CREATE OR REPLACE FUNCTION epg_stats.get_series_statio_all_tables_hist(g_ts bigint, g_interval interval)
 RETURNS TABLE(begin_ts bigint, end_ts bigint, relid oid, schemaname character varying, relname character varying, heap_blks_read bigint, heap_blks_hit bigint, idx_blks_read bigint, idx_blks_hit bigint, toast_blks_read bigint, toast_blks_hit bigint, tidx_blks_read bigint, tidx_blks_hit bigint)
 LANGUAGE plpgsql
AS $function$
declare 
  c1 REFCURSOR;
  row_data RECORD;
begin
	CREATE TEMP TABLE IF NOT EXISTS temp_get_series_statio_all_tables_hist_results (
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
      insert into temp_get_series_statio_all_tables_hist_results
    	select 
	      min(sath.ts) AS begin_ts,
	      max(sath.ts) AS end_ts, 
	      sath.relid, sath.schemaname, sath.relname, 
	      abs(max(sath.heap_blks_read) - coalesce(min(sath.heap_blks_read),0)) as heap_blks_read,
	      abs(max(sath.heap_blks_hit) - coalesce(min(sath.heap_blks_hit),0)) as heap_blks_hit,
	      abs(max(sath.idx_blks_read) - coalesce(min(sath.idx_blks_read),0)) as idx_blks_read,
	      abs(max(sath.idx_blks_hit) - coalesce(min(sath.idx_blks_hit),0)) as idx_blks_hit,
	      abs(max(sath.toast_blks_read) - coalesce(min(sath.toast_blks_read),0)) as toast_blks_read,      
	      abs(max(sath.toast_blks_hit) - coalesce(min(sath.toast_blks_hit),0)) as toast_blks_hit,
	      abs(max(sath.tidx_blks_read) - coalesce(min(sath.tidx_blks_read),0)) as tidx_blks_read,
	      abs(max(sath.tidx_blks_hit) - coalesce(min(sath.tidx_blks_hit),0)) as tidx_blks_hit
	    from 
	      epg_stats.statio_all_tables_hist  sath
	      where sath.ts in (row_data.current_snapshot, row_data.previous_snapshot)
	    group by sath.relid, sath.schemaname, sath.relname;				
    END LOOP;
    CLOSE c1;

	return query
	  select * from temp_get_series_statio_all_tables_hist_results;

	drop table if exists temp_get_series_statio_all_tables_hist_results;
end;
$function$
;
