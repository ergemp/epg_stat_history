-- DROP FUNCTION epg_stats.get_stat_checkpointer_hist(int8, interval);

CREATE OR REPLACE FUNCTION epg_stats.get_stat_checkpointer_hist(g_ts bigint, g_interval interval)
 RETURNS TABLE(
 	begin_ts bigint, 
 	end_ts bigint, 
 	num_timed bigint, 
 	num_requested bigint, 
 	num_done bigint,
 	restartpoints_timed bigint, 
 	restartpoints_req bigint, 
 	restartpoints_done bigint, 
 	write_time bigint, 
 	sync_time bigint, 
 	buffers_written bigint, 
 	slru_written bigint,
 	stats_reset timestamp with time zone)
 LANGUAGE plpgsql
AS $function$
DECLARE
	pg_version varchar(10);
BEGIN
	select substring(version(), length('PostgreSQL ') + 1, 2) into pg_version;

    RETURN QUERY 
    select 
      min(sch.ts), 
      max(sch.ts), 
      max(sch.num_timed) - min(sch.num_timed) AS num_timed,
      max(sch.num_requested) - min(sch.num_requested) AS num_requested,
      max(sch.num_done) - min(sch.num_done) AS num_done,
      max(sch.restartpoints_timed) - min(sch.restartpoints_timed) AS restartpoints_timed,
      max(sch.restartpoints_req) - min(sch.restartpoints_req) AS restartpoints_req,
      max(sch.restartpoints_done) - min(sch.restartpoints_done) AS restartpoints_done,
      max(sch.write_time) - min(sch.write_time) AS write_time,
      max(sch.sync_time) - min(sch.sync_time) AS sync_time,
      max(sch.buffers_written) - min(sch.buffers_written) AS buffers_written,
      max(sch.slru_written) - min(sch.slru_written) AS slru_written,      
      max(sch.stats_reset)      
    from 
      epg_stats.stat_checkpointer_hist  sch
    WHERE sch.ts IN (select ts from epg_stats.find_interval_boundaries(g_ts, g_interval))
    ;    
END
$function$
;