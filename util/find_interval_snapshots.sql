-- DROP FUNCTION epg_stats.find_interval_snapshots(int8, interval);

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
		date_trunc('minute', stat_intervals.ts_timestamp) >= date_trunc('minute', to_timestamp(g_ts))-(g_interval*2) and 
		date_trunc('minute', stat_intervals.ts_timestamp) <= date_trunc('minute', to_timestamp(g_ts))
	order by
		stat_intervals.ts_timestamp desc;
END
$function$
;
