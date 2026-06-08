-- drop procedure if exists epg_stats.fill_meta();

CREATE OR REPLACE PROCEDURE epg_stats.fill_meta()
 LANGUAGE plpgsql
AS $procedure$
DECLARE
  currentts bigint;
  pg_version varchar(10);
  pg_stat_statements_installed int;
BEGIN
	
    --select  * from pg_settings where name = 'server_version';
    select substring(version(), length('PostgreSQL ') + 1, 2) into pg_version;
    select count(*) into pg_stat_statements_installed from pg_extension where extname='pg_stat_statements';

	currentts := extract(epoch from now()::timestamp with time zone) ;

	execute 'INSERT INTO epg_stats.stat_intervals (ts_epoch, ts_timestamp) values (' || currentts || ',''' || to_timestamp(currentts)|| ''' )';

	execute 'INSERT INTO epg_stats.stat_all_tables_hist 
				(
				  ts ,
				  relid ,
				  schemaname ,
				  relname ,
				  seq_scan ,
				  seq_tup_read ,
				  idx_scan , 
				  idx_tup_fetch , 
				  n_tup_ins , 
				  n_tup_upd , 
				  n_tup_del , 
				  n_tup_hot_upd , 
				  n_live_tup , 
				  n_dead_tup , 
				  n_mod_since_analyze , 
				  last_vacuum , 
				  last_autovacuum ,
				  last_analyze ,
				  last_autoanalyze ,
				  vacuum_count , 
				  autovacuum_count , 
				  analyze_count , 
				  autoanalyze_count 				  
				)
				SELECT 
				  ' || currentts || ',
				  relid ,
				  schemaname ,
				  relname ,
				  seq_scan ,
				  seq_tup_read ,
				  idx_scan , 
				  idx_tup_fetch , 
				  n_tup_ins , 
				  n_tup_upd , 
				  n_tup_del , 
				  n_tup_hot_upd , 
				  n_live_tup , 
				  n_dead_tup , 
				  n_mod_since_analyze , 
				  last_vacuum , 
				  last_autovacuum ,
				  last_analyze ,
				  last_autoanalyze ,
				  vacuum_count , 
				  autovacuum_count , 
				  analyze_count , 
				  autoanalyze_count 
				FROM pg_stat_all_tables';
			
	execute 'INSERT INTO epg_stats.stat_all_indexes_hist 
				(				  
				  ts ,
				  relid ,
				  indexrelid ,
				  schemaname ,
				  relname ,
				  indexrelname ,
				  idx_scan ,
				  idx_tup_read , 
				  idx_tup_fetch 
				)
				SELECT 
				  ' || currentts || ' ,
				  relid ,
				  indexrelid ,
				  schemaname ,
				  relname ,
				  indexrelname ,
				  idx_scan ,
				  idx_tup_read , 
				  idx_tup_fetch 
				FROM pg_stat_all_indexes';		

	execute 'INSERT INTO epg_stats.statio_all_tables_hist
				(
					ts , 
					relid , 
					schemaname ,
					relname ,
					heap_blks_read , 
					heap_blks_hit ,
					idx_blks_read , 
					idx_blks_hit , 
					toast_blks_read , 
					toast_blks_hit ,
					tidx_blks_read , 
					tidx_blks_hit 
				)
				SELECT 
					' ||currentts || ' , 
					relid , 
					schemaname ,
					relname ,
					heap_blks_read , 
					heap_blks_hit ,
					idx_blks_read , 
					idx_blks_hit , 
					toast_blks_read , 
					toast_blks_hit ,
					tidx_blks_read , 
					tidx_blks_hit 
				FROM pg_statio_all_tables';
			
	execute 'INSERT INTO epg_stats.statio_all_indexes_hist
				(
					ts , 
					relid ,
					indexrelid ,
					schemaname ,
					relname ,
					indexrelname ,
					idx_blks_read , 
					idx_blks_hit 
				)
				SELECT 
					' || currentts || ' , 
					relid ,
					indexrelid ,
					schemaname ,
					relname ,
					indexrelname ,
					idx_blks_read , 
					idx_blks_hit  
					FROM pg_statio_all_indexes';
	
	/*			
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
				FROM pg_stat_activity';	
	*/

	execute 'INSERT INTO epg_stats.stat_archiver_hist
				(
					ts , 
					archived_count , 
					last_archived_wal ,
					last_archived_time ,
					failed_count , 
					last_failed_wal ,
					last_failed_time , 
					stats_reset 
				)
				SELECT 
					' || currentts || ' ,
					archived_count , 
					last_archived_wal ,
					last_archived_time ,
					failed_count , 
					last_failed_wal ,
					last_failed_time , 
					stats_reset 
				FROM pg_stat_archiver';
			
    if (cast(pg_version as integer) <= 16) then
		execute 'INSERT INTO epg_stats.stat_bgwriter_hist
					(
						ts ,
						checkpoints_timed , 
						checkpoints_req , 
						checkpoint_write_time ,
						checkpoint_sync_time ,
						buffers_checkpoint ,
						buffers_clean , 
						maxwritten_clean , 
						buffers_backend , 
						buffers_backend_fsync , 
						buffers_alloc , 
						stats_reset 
					)
					SELECT 
						' || currentts || ',
						checkpoints_timed , 
						checkpoints_req , 
						checkpoint_write_time ,
						checkpoint_sync_time ,
						buffers_checkpoint ,
						buffers_clean , 
						maxwritten_clean , 
						buffers_backend , 
						buffers_backend_fsync , 
						buffers_alloc , 
						stats_reset 
					FROM pg_stat_bgwriter';
	elsif (cast(pg_version as integer) > 16 ) then
		execute 'INSERT INTO epg_stats.stat_bgwriter_hist
					(
						ts ,
						buffers_clean , 
						maxwritten_clean , 
						buffers_alloc , 
						stats_reset 
					)
					SELECT 
						' || currentts || ',
						buffers_clean , 
						maxwritten_clean , 
						buffers_alloc , 
						stats_reset 
					FROM pg_stat_bgwriter';

		if (cast(pg_version as integer) = 17 ) then
			execute 'INSERT INTO epg_stats.stat_checkpointer_hist
						(
							ts ,
							num_timed , 
							num_requested , 
							restartpoints_timed , 
							restartpoints_req , 
							write_time , 
							sync_time , 
							buffers_written , 
							stats_reset 
						)
						SELECT 
							' || currentts || ',
							num_timed , 
							num_requested , 
							restartpoints_timed , 
							restartpoints_req , 
							write_time , 
							sync_time , 
							buffers_written , 
							stats_reset 
						FROM pg_stat_checkpointer';
		elsif (cast(pg_version as integer) >= 18 ) then
			execute 'INSERT INTO epg_stats.stat_checkpointer_hist
						(
							ts ,
							num_timed , 
							num_requested , 
							num_done , 
							restartpoints_timed , 
							restartpoints_req , 
							restartpoints_done , 
							write_time , 
							sync_time , 
							buffers_written , 
							slru_written,
							stats_reset 
						)
						SELECT 
							' || currentts || ',
							num_timed , 
							num_requested , 
							num_done , 
							restartpoints_timed , 
							restartpoints_req , 
							restartpoints_done , 
							write_time , 
							sync_time , 
							buffers_written , 
							slru_written,
							stats_reset 
						FROM pg_stat_checkpointer';
		end if;
	end if;

    if (pg_stat_statements_installed=1) then 
		if (cast(pg_version as integer) <= 12) then
			execute 'INSERT INTO epg_stats.stat_statements_hist 
						(
							ts ,
							userid ,
							dbid ,
							queryid ,
							query ,
							calls ,
							total_time ,
							min_time ,
							max_time ,
							mean_time ,
							stddev_time ,
							rows ,
							shared_blks_hit ,
							shared_blks_read ,
							shared_blks_dirtied ,
							shared_blks_written ,
							local_blks_hit ,
							local_blks_read ,
							local_blks_dirtied ,
							local_blks_written ,
							temp_blks_read ,
							temp_blks_written ,
							blk_read_time ,
							blk_write_time 
						)
						SELECT 
							' || currentts || ',
							userid ,
							dbid ,
							queryid ,
							query ,
							calls ,
							total_time ,
							min_time ,
							max_time ,
							mean_time ,
							stddev_time ,
							rows ,
							shared_blks_hit ,
							shared_blks_read ,
							shared_blks_dirtied ,
							shared_blks_written ,
							local_blks_hit ,
							local_blks_read ,
							local_blks_dirtied ,
							local_blks_written ,
							temp_blks_read ,
							temp_blks_written ,
							blk_read_time ,
							blk_write_time 
						FROM pg_stat_statements';
		elsif (cast(pg_version as integer) >= 13 and cast(pg_version as integer) <= 16) then
			execute 'INSERT INTO epg_stats.stat_statements_hist 
						(
							ts ,
							userid ,
							dbid ,
							queryid ,
							query ,
							calls ,
							plans,
							total_plan_time,
							min_plan_time, 
							max_plan_time, 
							mean_plan_time,
							stddev_plan_time, 
							total_exec_time,
							min_exec_time, 
							max_exec_time, 
							mean_exec_time,
							stddev_exec_time, 
							rows ,
							shared_blks_hit ,
							shared_blks_read ,
							shared_blks_dirtied ,
							shared_blks_written ,
							local_blks_hit ,
							local_blks_read ,
							local_blks_dirtied ,
							local_blks_written ,
							temp_blks_read ,
							temp_blks_written ,
							blk_read_time ,
							blk_write_time,
							wal_records, 
							wal_fpi,
							wal_bytes
						)
						SELECT 
							' || currentts || ',
							userid ,
							dbid ,
							queryid ,
							query ,
							calls ,
							plans,
							total_plan_time,
							min_plan_time, 
							max_plan_time, 
							mean_plan_time,
							stddev_plan_time, 
							total_exec_time,
							min_exec_time, 
							max_exec_time, 
							mean_exec_time,
							stddev_exec_time, 
							rows ,
							shared_blks_hit ,
							shared_blks_read ,
							shared_blks_dirtied ,
							shared_blks_written ,
							local_blks_hit ,
							local_blks_read ,
							local_blks_dirtied ,
							local_blks_written ,
							temp_blks_read ,
							temp_blks_written ,
							blk_read_time ,
							blk_write_time ,
							wal_records, 
							wal_fpi,
							wal_bytes
						FROM pg_stat_statements';
		elsif (cast(pg_version as integer) > 16) then
			execute 'INSERT INTO epg_stats.stat_statements_hist 
						(
							ts ,
							userid ,
							dbid ,
							queryid ,
							query ,
							calls ,
							plans,
							total_plan_time,
							min_plan_time, 
							max_plan_time, 
							mean_plan_time,
							stddev_plan_time, 
							total_exec_time,
							min_exec_time, 
							max_exec_time, 
							mean_exec_time,
							stddev_exec_time, 
							rows ,
							shared_blks_hit ,
							shared_blks_read ,
							shared_blks_dirtied ,
							shared_blks_written ,
							local_blks_hit ,
							local_blks_read ,
							local_blks_dirtied ,
							local_blks_written ,
							temp_blks_read ,
							temp_blks_written ,
							shared_blk_read_time ,
							shared_blk_write_time,
							local_blk_read_time ,
							local_blk_write_time,
							temp_blk_read_time ,
							temp_blk_write_time,
							wal_records, 
							wal_fpi,
							wal_bytes
						)
						SELECT 
							' || currentts || ',
							userid ,
							dbid ,
							queryid ,
							query ,
							calls ,
							plans,
							total_plan_time,
							min_plan_time, 
							max_plan_time, 
							mean_plan_time,
							stddev_plan_time, 
							total_exec_time,
							min_exec_time, 
							max_exec_time, 
							mean_exec_time,
							stddev_exec_time, 
							rows ,
							shared_blks_hit ,
							shared_blks_read ,
							shared_blks_dirtied ,
							shared_blks_written ,
							local_blks_hit ,
							local_blks_read ,
							local_blks_dirtied ,
							local_blks_written ,
							temp_blks_read ,
							temp_blks_written ,
							shared_blk_read_time ,
							shared_blk_write_time,
							local_blk_read_time ,
							local_blk_write_time,
							temp_blk_read_time ,
							temp_blk_write_time,
							wal_records, 
							wal_fpi,
							wal_bytes
						FROM pg_stat_statements';
		end if;
	end if;

	/*
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
				FROM pg_locks';
	*/

	execute 'INSERT INTO epg_stats.stat_database_hist 
				(
					ts ,
					datid ,
					datname	,
					numbackends ,
					xact_commit ,
					xact_rollback ,
					blks_read ,
					blks_hit ,
					tup_returned ,
					tup_fetched ,
					tup_inserted ,
					tup_updated ,
					tup_deleted ,
					conflicts ,
					temp_files ,
					temp_bytes ,
					deadlocks ,
					blk_read_time ,
					blk_write_time ,
					stats_reset 
				)
				SELECT 
					'|| currentts || ' ,
					datid ,
					datname	,
					numbackends ,
					xact_commit ,
					xact_rollback ,
					blks_read ,
					blks_hit ,
					tup_returned ,
					tup_fetched ,
					tup_inserted ,
					tup_updated ,
					tup_deleted ,
					conflicts ,
					temp_files ,
					temp_bytes ,
					deadlocks ,
					blk_read_time ,
					blk_write_time ,
					stats_reset 
				FROM pg_stat_database';	

	if (cast(pg_version as integer) >= 14 and cast(pg_version as integer) <= 17) then
		execute 'INSERT INTO epg_stats.stat_wal_hist
					(
						ts ,
						wal_records , 
						wal_fpi , 
						wal_bytes ,
						wal_buffers_full ,
						wal_write ,
						wal_sync , 
						wal_write_time , 
						wal_sync_time , 
						stats_reset 
					)
					SELECT 
						' || currentts || ',
						wal_records , 
						wal_fpi , 
						wal_bytes ,
						wal_buffers_full ,
						wal_write ,
						wal_sync , 
						wal_write_time , 
						wal_sync_time , 
						stats_reset 
					FROM pg_stat_wal';
	elsif (cast(pg_version as integer) > 17) then
		execute 'INSERT INTO epg_stats.stat_wal_hist
					(
						ts ,
						wal_records , 
						wal_fpi , 
						wal_bytes ,
						wal_buffers_full 
						stats_reset 
					)
					SELECT 
						' || currentts || ',
						wal_records , 
						wal_fpi , 
						wal_bytes ,
						wal_buffers_full 
						stats_reset 
					FROM pg_stat_wal';		
	end if;

	execute 'INSERT INTO epg_stats.pg_settings_hist 
				(
					ts ,
					name ,
					setting	,
					category 
				)
				SELECT 
					'|| currentts || ' ,
					name ,
					setting	,
					category 
				FROM pg_settings';						
			
END
$procedure$
;

--call epg_stats.fill_meta();