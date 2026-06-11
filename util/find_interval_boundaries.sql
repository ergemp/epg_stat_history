-- DROP FUNCTION epg_stats.find_interval_boundaries(int8, interval);

CREATE OR REPLACE FUNCTION epg_stats.find_interval_boundaries(g_ts bigint, g_interval interval)
 RETURNS TABLE(ts bigint)
 LANGUAGE plpgsql
AS $function$
DECLARE 
  act_ts bigint;
  begin_ts bigint;
  end_ts bigint;
BEGIN
  act_ts := EXTRACT(epoch FROM (to_timestamp(g_ts) - g_interval));
  
  select max(ts_epoch) into end_ts FROM epg_stats.stat_intervals where date_trunc('minute', ts_timestamp) <= date_trunc('minute', to_timestamp(g_ts));
  --select min(ts_epoch) into begin_ts from epg_stats.stat_intervals where date_trunc('minute', ts_timestamp) >= date_trunc('minute', to_timestamp(g_ts)) - g_interval;

	with min_ts as
	(
	select
		min(ts_epoch) as ts_epoch
	from
		epg_stats.stat_intervals
	where
		date_trunc('minute', ts_timestamp) >= date_trunc('minute', to_timestamp(g_ts)) - g_interval
		)
	select
		max(epg_stats.stat_intervals.ts_epoch) into begin_ts
	from
		epg_stats.stat_intervals,
		min_ts
	where
		epg_stats.stat_intervals.ts_epoch < min_ts.ts_epoch;


  if (end_ts = begin_ts) then
	select max(ts_epoch) into begin_ts from epg_stats.stat_intervals where ts_epoch < end_ts;
  end if;

  ts := begin_ts;
  RETURN NEXT;
  ts := end_ts;
  RETURN NEXT;  
END
$function$
;
