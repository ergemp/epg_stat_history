-- DROP FUNCTION epg_stats.get_statio_all_indexes_hist(int8, interval);

CREATE OR REPLACE FUNCTION epg_stats.get_statio_all_indexes_hist(g_ts bigint, g_interval interval)
 RETURNS TABLE(begin_ts bigint, end_ts bigint, relid oid, indexrelid oid, schemaname character varying, relname character varying, indexrelname character varying, idx_blks_read bigint, idx_blks_hit bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY 
    select 
      min(saih.ts) AS begin_ts, 
      max(saih.ts) AS end_ts, 
      saih.relid, saih.indexrelid, saih.schemaname, saih.relname, saih.indexrelname,
      abs(max(saih.idx_blks_read) - coalesce(min(saih.idx_blks_read),0)) as idx_blks_read,
      abs(max(saih.idx_blks_hit) - coalesce(min(saih.idx_blks_hit),0)) as idx_blks_hit
    from 
      epg_stats.statio_all_indexes_hist  saih
	where saih.ts in (select ts from epg_stats.find_interval_boundaries(g_ts, g_interval))
    group by saih.relid, saih.indexrelid, saih.schemaname, saih.relname, saih.indexrelname ;
    
END
$function$
;
