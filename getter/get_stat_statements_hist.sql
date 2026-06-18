-- DROP FUNCTION epg_stats.get_stat_statements_hist(int8, interval);

CREATE OR REPLACE FUNCTION epg_stats.get_stat_statements_hist(g_ts bigint, g_interval interval)
 RETURNS TABLE(begin_ts bigint, end_ts bigint, userid oid, dbid oid, queryid bigint, query text, calls bigint, total_time double precision, min_time double precision, max_time double precision, mean_time double precision, stddev_time double precision, rows bigint, shared_blks_hit bigint, shared_blks_read bigint, shared_blks_dirtied bigint, shared_blks_written bigint, local_blks_hit bigint, local_blks_read bigint, local_blks_dirtied bigint, local_blks_written bigint, temp_blks_read bigint, temp_blks_written bigint, blk_read_time double precision, blk_write_time double precision)
 LANGUAGE plpgsql
AS $function$
DECLARE 
  mints bigint;
  maxts bigint;
  pg_version varchar(10);
BEGIN

    select substring(version(), length('PostgreSQL ') + 1, 2) into pg_version;

    select min(fb.ts) into mints from epg_stats.find_interval_boundaries(g_ts, g_interval) fb;
    select min(fb.ts) into maxts from epg_stats.find_interval_boundaries(g_ts, g_interval) fb;

	if (cast(pg_version as integer) <= 12) then
	    RETURN QUERY 
	    select * from 
	    (
	    select 
	      min(ssh.ts) as begin_ts, max(ssh.ts) as end_ts, 
	      ssh.userid as userid, ssh.dbid as dbid, ssh.queryid as queryid, ssh.query as query, 
	      max(ssh.calls) - coalesce(min(ssh.calls),0) as calls, 
	      max(ssh.total_time) - coalesce(min(ssh.total_time),0) as total_time,
	      max(ssh.min_time) as min_time  ,
	      max(ssh.max_time) as max_time,
	      max(ssh.mean_time) as mean_time,
	      max(ssh.stddev_time) as stddev_time,
	      max(ssh.rows) -  coalesce(min(ssh.rows),0)  as rows,
	      max(ssh.shared_blks_hit) -  coalesce(min(ssh.shared_blks_hit),0)  as shared_blks_hit,
	      max(ssh.shared_blks_read) -  coalesce(min(ssh.shared_blks_read),0)  as shared_blks_read,
	      max(ssh.shared_blks_dirtied) - coalesce(min(ssh.shared_blks_dirtied),0)  as shared_blks_dirtied,
	      max(ssh.shared_blks_written) -  coalesce(min(ssh.shared_blks_written),0)  as shared_blks_written,
	      max(ssh.local_blks_hit) - coalesce(min(ssh.local_blks_hit),0) as local_blks_hit,
	      max(ssh.local_blks_read) - coalesce(min(ssh.local_blks_read),0) as local_blks_read,
	      max(ssh.local_blks_dirtied) - coalesce(min(ssh.local_blks_dirtied),0) as local_blks_dirtied,
	      max(ssh.local_blks_written) - coalesce(min(ssh.local_blks_written),0) as local_blks_written,      
	      max(ssh.temp_blks_read) - coalesce(min(ssh.temp_blks_read),0) as temp_blks_read,
	      max(ssh.temp_blks_written) - coalesce(min(ssh.temp_blks_written),0) as temp_blks_written,      
	      max(ssh.blk_read_time) - coalesce(min(ssh.blk_read_time),0) as blk_read_time,
	      max(ssh.blk_write_time) - coalesce(min(ssh.blk_write_time),0) as blk_write_time 
	    from 
	      epg_stats.stat_statements_hist  ssh
		where ssh.ts in (select ts from epg_stats.find_interval_boundaries(g_ts, g_interval))   
	    GROUP BY ssh.userid, ssh.dbid, ssh.queryid, ssh.query
	    ) as tt
	    where tt.calls > 0
	    ;  
	elsif (cast(pg_version as integer) >= 13 and cast(pg_version as integer) <= 16) then
 		RETURN QUERY 
	    select * from 
	    (
	    select 
	      min(ssh.ts) as begin_ts, max(ssh.ts) as end_ts, 
	      ssh.userid as userid, ssh.dbid as dbid, ssh.queryid as queryid, ssh.query as query, 
	      max(ssh.calls) - coalesce(min(ssh.calls),0) as calls, 
	      max(ssh.total_exec_time + ssh.total_plan_time) - coalesce(min(ssh.total_exec_time+ssh.total_plan_time),0) as total_time,
	      max(ssh.min_exec_time) as min_time  ,
	      max(ssh.max_exec_time) as max_time,
	      max(ssh.mean_exec_time) as mean_time,
	      max(ssh.stddev_exec_time) as stddev_time,
	      max(ssh.rows) -  coalesce(min(ssh.rows),0)  as rows,
	      max(ssh.shared_blks_hit) -  coalesce(min(ssh.shared_blks_hit),0)  as shared_blks_hit,
	      max(ssh.shared_blks_read) -  coalesce(min(ssh.shared_blks_read),0)  as shared_blks_read,
	      max(ssh.shared_blks_dirtied) - coalesce(min(ssh.shared_blks_dirtied),0)  as shared_blks_dirtied,
	      max(ssh.shared_blks_written) -  coalesce(min(ssh.shared_blks_written),0)  as shared_blks_written,
	      max(ssh.local_blks_hit) - coalesce(min(ssh.local_blks_hit),0) as local_blks_hit,
	      max(ssh.local_blks_read) - coalesce(min(ssh.local_blks_read),0) as local_blks_read,
	      max(ssh.local_blks_dirtied) - coalesce(min(ssh.local_blks_dirtied),0) as local_blks_dirtied,
	      max(ssh.local_blks_written) - coalesce(min(ssh.local_blks_written),0) as local_blks_written,      
	      max(ssh.temp_blks_read) - coalesce(min(ssh.temp_blks_read),0) as temp_blks_read,
	      max(ssh.temp_blks_written) - coalesce(min(ssh.temp_blks_written),0) as temp_blks_written,      
	      max(ssh.blk_read_time) - coalesce(min(ssh.blk_read_time),0) as blk_read_time,
	      max(ssh.blk_write_time) - coalesce(min(ssh.blk_write_time),0) as blk_write_time 
	    from 
	      epg_stats.stat_statements_hist  ssh
	    where ssh.ts in (select ts from epg_stats.find_interval_boundaries(g_ts, g_interval))   
	    GROUP BY ssh.userid, ssh.dbid, ssh.queryid, ssh.query
	    ) as tt
	    where tt.calls > 0
	    ;  
	elsif (cast(pg_version as integer) > 16) then
		RETURN QUERY 
	    select * from 
	    (
	    select 
	      min(ssh.ts) as begin_ts, max(ssh.ts) as end_ts, 
	      ssh.userid as userid, ssh.dbid as dbid, ssh.queryid as queryid, ssh.query as query, 
	      max(ssh.calls) - coalesce(min(ssh.calls),0) as calls, 
	      max(ssh.total_exec_time + ssh.total_plan_time) - coalesce(min(ssh.total_exec_time+ssh.total_plan_time),0) as total_time,
	      max(ssh.min_exec_time + ssh.min_plan_time) as min_time  ,
	      max(ssh.max_exec_time + ssh.max_plan_time) as max_time,
	      max(ssh.mean_exec_time + ssh.mean_plan_time) as mean_time,
	      max(ssh.stddev_exec_time + ssh.stddev_plan_time) as stddev_time,
	      max(ssh.rows) -  coalesce(min(ssh.rows),0)  as rows,
	      max(ssh.shared_blks_hit) -  coalesce(min(ssh.shared_blks_hit),0)  as shared_blks_hit,
	      max(ssh.shared_blks_read) -  coalesce(min(ssh.shared_blks_read),0)  as shared_blks_read,
	      max(ssh.shared_blks_dirtied) - coalesce(min(ssh.shared_blks_dirtied),0)  as shared_blks_dirtied,
	      max(ssh.shared_blks_written) -  coalesce(min(ssh.shared_blks_written),0)  as shared_blks_written,
	      max(ssh.local_blks_hit) - coalesce(min(ssh.local_blks_hit),0) as local_blks_hit,
	      max(ssh.local_blks_read) - coalesce(min(ssh.local_blks_read),0) as local_blks_read,
	      max(ssh.local_blks_dirtied) - coalesce(min(ssh.local_blks_dirtied),0) as local_blks_dirtied,
	      max(ssh.local_blks_written) - coalesce(min(ssh.local_blks_written),0) as local_blks_written,      
	      max(ssh.temp_blks_read) - coalesce(min(ssh.temp_blks_read),0) as temp_blks_read,
	      max(ssh.temp_blks_written) - coalesce(min(ssh.temp_blks_written),0) as temp_blks_written,      
	      max(ssh.local_blk_read_time + ssh.shared_blk_read_time + ssh.temp_blk_read_time) - coalesce(min(ssh.local_blk_read_time + ssh.shared_blk_read_time + ssh.temp_blk_read_time),0) as blk_read_time,
	      max(ssh.local_blk_write_time + ssh.shared_blk_write_time + ssh.temp_blk_write_time) - coalesce(min(ssh.local_blk_write_time + ssh.shared_blk_write_time + + ssh.temp_blk_write_time),0) as blk_write_time 
	    from 
	      epg_stats.stat_statements_hist  ssh
	    where ssh.ts in (select ts from epg_stats.find_interval_boundaries(g_ts, g_interval)) 
	    GROUP BY ssh.userid, ssh.dbid, ssh.queryid, ssh.query
	    ) as tt
	    where tt.calls > 0
	    ;  
	end if;  
END
$function$
;
