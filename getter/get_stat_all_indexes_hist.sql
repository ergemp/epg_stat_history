-- DROP FUNCTION epg_stats.get_stat_all_indexes_hist(int8, interval);

CREATE OR REPLACE FUNCTION epg_stats.get_stat_all_indexes_hist(g_ts bigint, g_interval interval)
 RETURNS TABLE(begin_ts bigint, end_ts bigint, relid oid, indexrelid oid, schemaname character varying, relname character varying, indexrelname character varying, idx_scan bigint, idx_tup_read bigint, idx_tup_fetch bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY 
    select 
      min(saih.ts) AS begin_ts, 
      max(saih.ts) AS end_ts, 
      saih.relid, saih.indexrelid, saih.schemaname, saih.relname, saih.indexrelname,
      abs(coalesce(max(saih.idx_scan),0) - coalesce(min(saih.idx_scan),0)) as idx_scan,
      abs(max(saih.idx_tup_read) - coalesce(min(saih.idx_tup_read),0)) as idx_tup_read,
      abs(max(saih.idx_tup_fetch) - coalesce(min(saih.idx_tup_fetch),0))  as idx_tup_fetch
    from 
      epg_stats.stat_all_indexes_hist  saih
    WHERE saih.ts IN (select ts from epg_stats.find_interval_boundaries(g_ts, g_interval))   
    group by saih.relid, saih.indexrelid, saih.schemaname, saih.relname, saih.indexrelname ;
    
END
$function$
;