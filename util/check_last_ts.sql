drop function if exists epg_stats.check_last_ts();

CREATE OR replace function epg_stats.check_last_ts() RETURNS TABLE(tts bigint, ttime timestamp) as
$$
declare
  retval bigint;
BEGIN
  SELECT max(ts), to_timestamp(max(ts)) into tts, ttime  FROM epg_stats.stat_activity_hist;
  return next;
end
$$
language plpgsql

--select * from fv_stats.check_last_ts();