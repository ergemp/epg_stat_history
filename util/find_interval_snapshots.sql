CREATE OR REPLACE FUNCTION epg_stats.find_interval_snapshots(g_ts bigint, g_interval interval)
 RETURNS TABLE(ts_epoch bigint, ts_timestamp timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
DECLARE 
  act_ts bigint;
  begin_ts bigint;
  end_ts bigint;
BEGIN
  RETURN QUERY
	select
		stat_intervals.ts_epoch, stat_intervals.ts_timestamp
	from
		epg_stats.stat_intervals
	where
		stat_intervals.ts_timestamp between to_timestamp(g_ts)-g_interval and to_timestamp(g_ts)
	order by
		stat_intervals.ts_timestamp desc;
END
$function$
;
