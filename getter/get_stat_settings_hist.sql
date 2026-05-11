-- DROP FUNCTION epg_stats.get_stat_settings_hist(int8, interval);

CREATE OR REPLACE FUNCTION epg_stats.get_stat_settings_hist(g_ts bigint, g_interval interval)
 RETURNS TABLE(ts bigint, name text, setting text, category text)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY 
    select 
      psh.ts, psh.name, psh.setting, psh.category
    from 
      epg_stats.pg_settings_hist  psh
    WHERE psh.ts IN (select min(fb.ts) from epg_stats.find_interval_boundaries(g_ts, g_interval) fb) 
    ;    
END
$function$
;
