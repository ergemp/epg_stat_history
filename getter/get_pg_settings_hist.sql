drop function IF EXISTS epg_stats.get_pg_settings_hist;

CREATE OR replace FUNCTION epg_stats.get_pg_settings_hist(g_ts bigint, g_interval interval) RETURNS TABLE 
(
    ts bigint,
    name text,
    setting text,
    category text
)
AS 
$$
BEGIN
    RETURN QUERY 
    select 
      psh.ts, psh.name, psh.setting, psh.category
    from 
      epg_stats.pg_settings_hist  psh
    WHERE psh.ts IN (select min(fb.ts) from epg_stats.find_interval(g_ts, g_interval) fb) 
    ;    
END
$$
LANGUAGE plpgsql