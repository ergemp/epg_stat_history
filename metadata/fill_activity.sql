-- DROP PROCEDURE epg_stats.fill_activity();

CREATE OR REPLACE PROCEDURE epg_stats.fill_activity()
 LANGUAGE plpgsql
AS $procedure$
DECLARE
  currentts bigint;
  pg_version varchar(10);
BEGIN
	
    --select  * from pg_settings where name = 'server_version';
    select substring(version(), length('PostgreSQL ') + 1, 2) into pg_version;
	currentts := extract(epoch from clock_timestamp()::timestamp with time zone) ;
				
	execute 'INSERT INTO epg_stats.stat_activity_hist 
				(
				  ts,
				  datid,
				  datname,
				  pid,
				  usesysid,
				  usename,
				  application_name,
				  client_addr,
				  client_hostname,
				  client_port,
				  backend_start,
				  xact_start,
				  query_start,
				  state_change,
				  wait_event_type,
				  wait_event,
				  state,
				  backend_xid,
				  backend_xmin,
				  query,
				  backend_type
				)
				SELECT 				 
				  ' || currentts|| ',
				  datid,
				  datname,
				  pid,
				  usesysid,
				  usename,
				  application_name,
				  client_addr,
				  client_hostname,
				  client_port,
				  backend_start,
				  xact_start,
				  query_start,
				  state_change,
				  wait_event_type,
				  wait_event,
				  state,
				  backend_xid,
				  backend_xmin,
				  query,
				  backend_type
				FROM pg_stat_activity
				-- WHERE state != ''idle''
				';	

	execute 'INSERT INTO epg_stats.stat_locks_hist 
				(
					ts ,
					locktype ,
					database , 
					relation ,
					page ,
					tuple ,
					virtualxid , 
					transactionid , 
					classid ,
					objid ,
					objsubid ,
					virtualtransaction , 
					pid , 
					mode , 
					granted , 
					fastpath 
				)
				SELECT 
					' || currentts || ' ,
					locktype ,
					database , 
					relation ,
					page ,
					tuple ,
					virtualxid , 
					transactionid , 
					classid ,
					objid ,
					objsubid ,
					virtualtransaction , 
					pid , 
					mode , 
					granted , 
					fastpath 
				FROM pg_locks
				--WHERE mode != ''AccessShareLock''
				';
END
$procedure$
;
