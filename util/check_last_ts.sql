-- drop function if exists epg_stats.check_last_ts();

CREATE OR REPLACE FUNCTION epg_stats.check_last_ts()
 RETURNS TABLE(tts bigint, ttime timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
declare
  retval bigint;
BEGIN
  SELECT max(ts_epoch), max(ts_timestamp) into tts, ttime  FROM epg_stats.stat_intervals;
  return next;
end
$function$
;


--select * from fv_stats.check_last_ts();