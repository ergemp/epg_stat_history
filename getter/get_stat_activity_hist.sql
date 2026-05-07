-- DROP FUNCTION epg_stats.get_stat_activity_hist(int8, interval);

CREATE OR REPLACE FUNCTION epg_stats.get_stat_activity_hist(g_ts bigint, g_interval interval)
 RETURNS TABLE(ts bigint, datid oid, datname character varying, pid integer, usesysid oid, usename character varying, application_name text, client_addr inet, client_hostname text, client_port integer, backend_start timestamp with time zone, xact_start timestamp with time zone, query_start timestamp with time zone, state_change timestamp with time zone, wait_event_type text, wait_event text, state text, backend_xid xid, backend_xmin xid, query text, backend_type text)
 LANGUAGE plpgsql
AS $function$
DECLARE 
  mints bigint;
  maxts bigint;
BEGIN
    RETURN QUERY 
    select 
      sah.ts, sah.datid, sah.datname, sah.pid,
      sah.usesysid, sah.usename, sah.application_name, 
      sah.client_addr, sah.client_hostname, sah.client_port, 
      sah.backend_start, sah.xact_start, sah.query_start, sah.state_change, 
      sah.wait_event_type, sah.wait_event, sah.state, 
      sah.backend_xid, sah.backend_xmin, sah.query, 
      sah.backend_type 
    from 
      epg_stats.stat_activity_hist sah
    where sah.ts between
      (select min(fb.ts) from epg_stats.find_interval_boundaries(g_ts, g_interval) fb) 
      and 
      (select max(fb.ts) from epg_stats.find_interval_boundaries(g_ts, g_interval) fb)                       
    ;    
END
$function$
;