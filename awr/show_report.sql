-- DROP PROCEDURE epg_stats.show_report(int8, interval);

CREATE OR REPLACE PROCEDURE epg_stats.show_report(IN g_ts bigint, IN g_interval interval)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
  act_ts bigint;
  begin_time timestamp;
  end_time timestamp;
  dbname text;
  v_tup_returned numeric;
  v_tup_fetched numeric;
  v_tup_inserted numeric;
  v_tup_updated numeric;
  v_tup_deleted numeric;
  dbcachehitratio numeric;
  mb_hit numeric;
  mb_read numeric;
  tempfiles numeric;
  tempmbs numeric;
  totalcommits numeric;
  totalrollbacks numeric;
  totalreadtimesec numeric;
  totalwritetimesec numeric;
  statslastreset timestamp with time zone;
  databasesize text;
  databaseblocksize text;
  pg_stat_statements_installed int;

  currenttimestamp timestamp with time zone;
  currenttxid text;

  oldest_current_xid  text;
  autovacuum_freeze_max_age  text;
  tx_remaining_before_shutdown text;
  pct_towards_emergency_autovac  text;
  pg_version text;

  tablecachehitratio numeric;
  indexcachehitratio numeric;

  general_params_curr record;
  parallel_params_curr record;
  autovacuum_params_curr record;
  wal_params_curr record;
  top_table_size_curr record;
  temp_query_cur record;
  long_query_cur record;
  most_query_cur record;
  bloats_curr record;
  table_wraparound_curr record;
  archiver_cur record;
  checkpoints_cur record;
  memory_pressure_cur record;
  top_backend_count_cur record;
  top_lock_count_cur record;
  top_wait_eventcount_cur record;
  seq_scan_tables record;
  table_cache_hit_ratio record;
begin    
	select count(*) into pg_stat_statements_installed from pg_extension where extname='pg_stat_statements';
    select substring(version(), length('PostgreSQL ') + 1, 2) into pg_version;

    select 
      to_timestamp(begin_ts) , 
      to_timestamp(end_ts)  ,
      datname,
	  tup_returned,
	  tup_fetched,
	  tup_inserted,
	  tup_updated,
	  tup_deleted,
      round(100 * blks_hit / cast((blks_read + blks_hit) as numeric),2),
	  (blks_hit*8192)/1024/1024 as mb_hit,
	  (blks_read*8192)/1024/1024 as mb_read,
      temp_files,
      temp_bytes/1024/1024 as temp_mb,
      xact_commit,
	  xact_rollback,
      blk_read_time/1000 as blk_read_time_sec,
      blk_write_time/1000 as blk_write_time_sec,
      stats_reset
	into 
      begin_time,
      end_time,
      dbname,
	  v_tup_returned,
	  v_tup_fetched,
	  v_tup_inserted,
	  v_tup_updated,
	  v_tup_deleted,
      dbcachehitratio,
	  mb_hit,
	  mb_read,
      tempfiles,
      tempmbs,
      totalcommits,
	  totalrollbacks,
      totalreadtimesec,
      totalwritetimesec,
      statslastreset
    from epg_stats.get_stat_database_hist(g_ts, g_interval)
    where datname = current_database();

    select pg_size_pretty(pg_database_size(current_database())) into databasesize;
    select current_setting('block_size') into databaseblocksize;

    select 
      age(datfrozenxid),
      current_setting('autovacuum_freeze_max_age') ,      
      round(100*(age(datfrozenxid)/current_setting('autovacuum_freeze_max_age')::float)),
	  2000000000 - age(datfrozenxid) AS tx_remainingbefore_shutdown  
      into 
      oldest_current_xid,
      autovacuum_freeze_max_age,
      pct_towards_emergency_autovac,
      tx_remaining_before_shutdown
    from pg_database 
    where datname = current_database();

    raise notice '--------------- %', chr(10);
    raise notice 'Report Summary %', chr(10) ;
    raise notice '--------------- %', chr(10);
   
    raise notice 'database name: % %', dbname, chr(10);
    raise notice 'begin snapshot: % %', begin_time, chr(10);
    raise notice 'end snapshot: % %', end_time, chr(10);
    raise notice '--------------- % %', chr(10), chr(10);
  
    raise notice '-------------------- %', chr(10);
    raise notice 'Database Level Usage %', chr(10);
    raise notice '-------------------- %', chr(10);
   
    raise notice 'Cache Hit Ratio: % %', dbcachehitratio, chr(10);
    raise notice 'Total Used Temporary Files: % %', tempfiles, chr(10);
    raise notice 'Total Used Temporary MBs: % %', tempmbs, chr(10);
    raise notice 'Total Commits: % %', totalcommits, chr(10);
    raise notice 'Total Rollbacks: % %', totalrollbacks, chr(10);
    raise notice 'Total Read Time (Sec): % %', totalreadtimesec, chr(10);
    raise notice 'Total Write Time (Sec): % %', totalwritetimesec, chr(10);
    raise notice 'Total Read MB: % %', mb_read, chr(10);
    raise notice 'Total Hit MB: % %', mb_hit, chr(10);
    raise notice 'Total Database Size (current): % %', databasesize, chr(10);
    raise notice 'Total Database Block Size (current): % %', databaseblocksize, chr(10);

    raise notice '-------------------- %', chr(10);
    raise notice 'Tuple Stats %', chr(10);
    raise notice '-------------------- %', chr(10);

	raise notice 'Tuples Returned: % %', v_tup_returned, chr(10);
    raise notice 'Tuples Fetched: % %', v_tup_fetched, chr(10);
	raise notice 'Tuples Inserted: % %', v_tup_inserted, chr(10);
	raise notice 'Tuples Updated: % %', v_tup_updated, chr(10);
	raise notice 'Tuples Deleted: % %', v_tup_deleted, chr(10);

    raise notice '-------------------- % %', chr(10), chr(10);
   
    raise notice '-------------------- %', chr(10);
    raise notice 'TX Wraparound (current) %', chr(10);
    raise notice '-------------------- %', chr(10);
   
    raise notice 'oldest_current_xid: % %', oldest_current_xid, chr(10);
    raise notice 'autovacuum_freeze_max_age: % %', autovacuum_freeze_max_age, chr(10);
    raise notice 'pct_towards_emergency_autovac: % %', pct_towards_emergency_autovac, chr(10);
    raise notice 'tx_remaining_before_shutdown: % %', tx_remaining_before_shutdown, chr(10);
    raise notice '-------------------- % %', chr(10), chr(10);
   
    raise notice '-------------------- % ', chr(10);
    raise notice 'Top 20 Wait events (counts) %', chr(10);
    raise notice '-------------------- %', chr(10);
   
    --
    -- header for top wait event (counts)
    --
    raise notice '% % % % % % ', format('%-50s','wait_event_type'), chr(9), format('%-50s','wait_event'), chr(9), 'total_waits', chr(10) ;
   
    FOR top_wait_eventcount_cur IN
      select 
        format('%-50s',wait_event_type) as wait_event_type, 
        format('%-50s',wait_event) as wait_event, 
        --to_char(count(*), 'FM0G000') as total_waits
        count(*) as total_waits
      from epg_stats.get_stat_activity_hist(g_ts, g_interval) 
      where wait_event_type is not null
      group by wait_event_type, wait_event
      order by 3 desc
      limit 20
    loop	    
	    raise notice '% % % % % % ', top_wait_eventcount_cur.wait_event_type, chr(9), top_wait_eventcount_cur.wait_event, chr(9), top_wait_eventcount_cur.total_waits, chr(9) ;
  	    --raise notice '%', chr(10);	  
    END LOOP;

    raise notice '-------------------- % %', chr(10), chr(10);
   	
    raise notice '-------------------- % ', chr(10);
    raise notice 'Top 20 Locks (counts) %', chr(10);
    raise notice '-------------------- %', chr(10);
   
    --
    -- header for top locks (counts)
    --
    raise notice '% % % % % % ', format('%-50s','locktype'), chr(9), format('%-50s','mode'), chr(9), 'total', chr(10) ;
   
    FOR top_lock_count_cur IN
      select 
        format('%-50s',locktype) as locktype, 
        format('%-50s',mode) as mode, 
        count(*) as total
      from epg_stats.get_stat_locks_hist(g_ts, g_interval) 
      group by locktype, mode
      order by 3 desc
      limit 20
    loop	    
	    raise notice '% % % % % % ', top_lock_count_cur.locktype, chr(9), top_lock_count_cur.mode, chr(9), top_lock_count_cur.total, chr(9) ;
  	    --raise notice '%', chr(10);	  
    END LOOP;

    raise notice '-------------------- % %', chr(10), chr(10);

    raise notice '-------------------- ' ;
    raise notice 'Top 20 Backend Type (counts) ';
    raise notice '-------------------- ';
   
    --
    -- header for top backend types (counts)
    --
    raise notice '% % % % ', format('%-40s','backend_type'), chr(9), 'total', chr(10) ;
   
    FOR top_backend_count_cur IN
		select
			datname,
			format('%-40s',backend_type) as backend_type,
			count(*) as total
		from
			epg_stats.get_stat_activity_hist(g_ts, g_interval)
		where 
			datname=current_database() and
			state != 'idle'
		group by
			datname,
			backend_type
		order by 3 desc
		limit 20
    loop	    
	    raise notice '% % % % ', top_backend_count_cur.backend_type, chr(9), top_backend_count_cur.total, chr(9) ;
    END LOOP;

    raise notice '-------------------- % %', chr(10), chr(10);

    raise notice '-------------------- % ', chr(10);
    raise notice 'Memory Request Per Snapshot (mb) %', chr(10);
    raise notice '-------------------- %', chr(10);

	--
	-- header for memory pressure
   	--
    raise notice '% % % % % % % %', format('%-40s','begin_ts'), chr(9), 
								 	format('%-40s','buffers_alloc(mb)'), chr(9), 
								 	format('%-40s','buffers_clean(mb)'), chr(9),
								 	format('%-40s','maxwritten_clean'), chr(10) ;
	FOR memory_pressure_cur IN
		select
			format('%-40s', (buffers_alloc * 8192)/1024/1024) as buffers_alloc ,
		    format('%-40s', (buffers_clean * 8192)/1024/1024) as buffers_clean ,
			format('%-40s', (maxwritten_clean * 8192)/1024/1024) as maxwritten_clean ,
			format('%-40s', to_timestamp(begin_ts)) as begin_ts
		from
			epg_stats.get_series_bgwriter_hist(g_ts, g_interval)
	LOOP
	    raise notice '% % % % % % % %', memory_pressure_cur.begin_ts, chr(9), 
										memory_pressure_cur.buffers_alloc, chr(9), 
										memory_pressure_cur.buffers_clean, chr(9), 
										memory_pressure_cur.maxwritten_clean, chr(9) ;
	END LOOP;

	raise notice '-------------------- % %', chr(10), chr(10);

	raise notice '-------------------- % ', chr(10);
    raise notice 'Checkpoint Stats %', chr(10);
    raise notice '-------------------- %', chr(10);

	--
	-- header for checkpoints
   	--
    raise notice '% % % % % % % % % % % % ', format('%-40s','begin_ts'), chr(9),
							 format('%-40s','checkpoints_timed'), chr(9), 
							 format('%-40s','checkpoints_requested'), chr(9), 
							 format('%-40s','checkpoint_write_time'), chr(9), 
							 format('%-40s','checkpoint_sync_time'), chr(9), 
							 format('%-40s','buffers_checkpoint(mb)'), chr(10) ;


	if (cast(pg_version as integer) <= 16) then
		FOR checkpoints_cur IN
			select
				format('%-40s', to_timestamp(begin_ts)) as begin_ts,
				format('%-40s', checkpoints_timed) as checkpoints_timed ,
				format('%-40s', checkpoints_req) as checkpoints_requested ,
				format('%-40s', checkpoint_write_time) as checkpoint_write_time ,
				format('%-40s', checkpoint_sync_time) as checkpoint_sync_time ,
				format('%-40s', (buffers_checkpoint*8192)/1024/1024) as buffers_checkpoint
			from
				epg_stats.get_series_bgwriter_hist(g_ts, g_interval)
		LOOP
		    raise notice '% % % % % % % % % % % %', checkpoints_cur.begin_ts, chr(9), 
													checkpoints_cur.checkpoints_timed, chr(9),
													checkpoints_cur.checkpoints_requested, chr(9),
													checkpoints_cur.checkpoint_write_time, chr(9),
													checkpoints_cur.checkpoint_sync_time, chr(9),
													checkpoints_cur.buffers_checkpoint, chr(9) ;
		END LOOP;
	else
		FOR checkpoints_cur IN
			select
				format('%-40s', to_timestamp(begin_ts)) as begin_ts,
				format('%-40s', num_timed) as checkpoints_timed ,
				format('%-40s', num_requested) as checkpoints_requested ,
				format('%-40s', write_time) as checkpoint_write_time ,
				format('%-40s', sync_time) as checkpoint_sync_time ,
				format('%-40s', (buffers_writtent*8192)/1024/1024) as buffers_checkpoint
			from
				epg_stats.get_series_checkpointer_hist(g_ts, g_interval)
		LOOP
		    raise notice '% % % % % % % % % % % %', checkpoints_cur.begin_ts, chr(9), 
													checkpoints_cur.checkpoints_timed, chr(9),
													checkpoints_cur.checkpoints_requested, chr(9),
													checkpoints_cur.checkpoint_write_time, chr(9),
													checkpoints_cur.checkpoint_sync_time, chr(9),
													checkpoints_cur.buffers_checkpoint, chr(9) ;
		END LOOP;

	end if;

	raise notice '-------------------- % %', chr(10), chr(10);

	raise notice '-------------------- % ', chr(10);
    raise notice 'Archiver Stats (mb) %', chr(10);
    raise notice '-------------------- %', chr(10);

	--
	-- header for archiver stats
   	--
    raise notice '% % % % % % % %', format('%-40s','begin_ts'), chr(9), 
								 	format('%-40s','end_ts(mb)'), chr(9), 
								 	format('%-40s','archived_count'), chr(9),
								 	format('%-40s','failed_count'), chr(10) ;
	FOR archiver_cur IN
		select
			format('%-40s',to_timestamp(begin_ts)) as begin_ts,
			format('%-40s',to_timestamp(end_ts)) as end_ts,
			format('%-40s',archived_count) as archived_count,
			format('%-40s',failed_count) as failed_count
		from
			epg_stats.get_series_archiver_hist(g_ts, g_interval)
		order by
			begin_ts desc
	LOOP
	    raise notice '% % % % % % % %', archiver_cur.begin_ts, chr(9), 
										archiver_cur.end_ts, chr(9), 
										archiver_cur.archived_count, chr(9), 
										archiver_cur.failed_count, chr(9) ;
	END LOOP;

	raise notice '-------------------- % %', chr(10), chr(10);

    --
    -- table and index cache hit ratios
    --
    SELECT 
      round(100 * sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)),2) into tablecachehitratio
    FROM 
      epg_stats.get_statio_all_tables_hist(g_ts, g_interval);
  
    SELECT 
      round(100 * sum(idx_blks_hit) / (sum(idx_blks_hit) + sum(idx_blks_read)),2) into indexcachehitratio
    FROM 
      epg_stats.get_statio_all_indexes_hist(g_ts, g_interval);  
  
	raise notice '------------------ %', chr(10);
    raise notice 'Memory Efficiency  %', chr(10);
    raise notice '------------------ %', chr(10);
   
    raise notice 'Table Cache Hit Ratio: % %', tablecachehitratio, chr(10);
    raise notice 'Index Cache Hit Ratio: % % %', indexcachehitratio, chr(10), chr(10);
   
    raise notice '------------- %', chr(10);
    raise notice 'IO Efficiency %', chr(10);
    raise notice '------------- %', chr(10);   
   
    raise notice '-------------- %', chr(10);
    raise notice 'Top 10 Seq Scan Read Tables %', chr(10);
    raise notice '-------------- %', chr(10);      
     
    --
    -- header for top sequential read tables
    --   
    raise notice '% % % % % % % % % % % % % % ', 
   					format('%-20s','seq_scan_ratio'), chr(9), 
   					format('%-50s','schemaname'), chr(9), 
   					format('%-60s','relname'), chr(9),
   					format('%-20s','seq_scan'), chr(9),
   					format('%-20s','idx_scan'), chr(9),
   					format('%-20s','seq_tup_read'), chr(9),
   					format('%-20s','idx_tup_fetch'), chr(10)   					
   				;
   
    FOR seq_scan_tables IN
		select
			100 * seq_scan / case
				when (idx_scan + seq_scan) = 0 then 1
				else (idx_scan + seq_scan)
			end as seq_scan_ratio,
			schemaname,
			relname,
			seq_scan,
			idx_scan,
			seq_tup_read,
			idx_tup_fetch
		from
			epg_stats.get_stat_all_tables_hist(g_ts, g_interval)
		where
			schemaname not in ('information_schema', 'pg_catalog', 'pg_toast', 'epg_stats')
			and idx_scan is not null
			and seq_scan is not null
		order by
			1 desc,6 desc
		limit 10
    loop
	    raise notice '% % % % % % % % % % % % % % ', 
	   		format('%-20s', seq_scan_tables.seq_scan_ratio), chr(9),
	   		format('%-50s',seq_scan_tables.schemaname), chr(9),
	   		format('%-60s',seq_scan_tables.relname), chr(9),
	   		format('%-20s',seq_scan_tables.seq_scan), chr(9),
	   		format('%-20s',seq_scan_tables.idx_scan), chr(9),
	   		format('%-20s',seq_scan_tables.seq_tup_read), chr(9),	   		
	   		format('%-20s',seq_scan_tables.idx_tup_fetch), chr(10)	   		
	   		;
    END LOOP;
    
    raise notice '-------------------- % %', chr(10), chr(10);
   
	raise notice '-------------- %', chr(10);
    raise notice 'Top 10 Seq Scan Requested Tables %', chr(10);
    raise notice '-------------- %', chr(10);      
     
    --
    -- header for top sequential read tables
    --   
    raise notice '% % % % % % % % % % % % % % ', 
   					format('%-20s','seq_scan_ratio'), chr(9), 
   					format('%-50s','schemaname'), chr(9), 
   					format('%-60s','relname'), chr(9),
   					format('%-20s','seq_scan'), chr(9),
   					format('%-20s','idx_scan'), chr(9),
   					format('%-20s','seq_tup_read'), chr(9),
   					format('%-20s','idx_tup_fetch'), chr(10)   					
   				;
   
    FOR seq_scan_tables IN
		select
			100 * seq_scan / case
				when (idx_scan + seq_scan) = 0 then 1
				else (idx_scan + seq_scan)
			end as seq_scan_ratio,
			schemaname,
			relname,
			seq_scan,
			idx_scan,
			seq_tup_read,
			idx_tup_fetch
		from
			epg_stats.get_stat_all_tables_hist(g_ts, g_interval)
		where
			schemaname not in ('information_schema', 'pg_catalog', 'pg_toast', 'epg_stats')
			and idx_scan is not null
			and seq_scan is not null
		order by
			1 desc,4 desc
		limit 10
    loop
	    
	    raise notice '% % % % % % % % % % % % % % ', 
	   		format('%-20s', seq_scan_tables.seq_scan_ratio), chr(9),
	   		format('%-50s',seq_scan_tables.schemaname), chr(9),
	   		format('%-60s',seq_scan_tables.relname), chr(9),
	   		format('%-20s',seq_scan_tables.seq_scan), chr(9),
	   		format('%-20s',seq_scan_tables.idx_scan), chr(9),
	   		format('%-20s',seq_scan_tables.seq_tup_read), chr(9),	   		
	   		format('%-20s',seq_scan_tables.idx_tup_fetch), chr(10)	   		
	   		;

    END LOOP;
    
    raise notice '-------------------- % %', chr(10), chr(10);

   
    raise notice '-------------- %', chr(10);
    raise notice 'Cache HIT Ratio for tables  %', chr(10);
    raise notice '-------------- %', chr(10);
      
    --
    -- header for top sequencial read tables
    --
    raise notice '% % % % % % % % ', 
   					format('%-50s','table_name'), chr(9), 
   					format('%-20s','from_disk'), chr(9), 
   					format('%-20s','from_cache'), chr(9),
   					format('%-20s','cache_hit_ratio_percentage'), chr(10);    

    FOR table_cache_hit_ratio IN
     	select
			*
		from
			(
			select
				relname as table_name,
				( (coalesce(heap_blks_read, 0) + coalesce(idx_blks_read, 0) + coalesce(toast_blks_read, 0) + coalesce(tidx_blks_read, 0)) ) as from_disk,
				( (coalesce(heap_blks_hit, 0) + coalesce(idx_blks_hit, 0) + coalesce(toast_blks_hit, 0) + coalesce(tidx_blks_hit, 0)) ) as from_cache,
				case
					when (heap_blks_hit + heap_blks_read) = 0 then 0
					else round(100.0 * heap_blks_hit / (heap_blks_hit + heap_blks_read), 2)
				end as cache_hit_ratio_percentage
			from
				epg_stats.get_statio_all_tables_hist(g_ts, g_interval)
		) t
		order by
			cache_hit_ratio_percentage,
			from_disk desc
		limit 10
      loop
	      
	      raise notice '% % % % % % % % ', 
   					format('%-50s',table_cache_hit_ratio.table_name), chr(9), 
   					format('%-20s',table_cache_hit_ratio.from_disk), chr(9), 
   					format('%-20s',table_cache_hit_ratio.from_cache), chr(9),
   					format('%-20s',table_cache_hit_ratio.cache_hit_ratio_percentage), chr(10)
   				;    
   			
    END LOOP;
   
	if (pg_stat_statements_installed=1) then
	    raise notice '-------------------- % %', chr(10), chr(10);
	   
	    raise notice '---------- %', chr(10);
	    raise notice 'Temp Usage %', chr(10);
	    raise notice '---------- %', chr(10);
	   
	    raise notice '---------- %', chr(10);
	    raise notice 'Top 10 Temp Usage By Queries %', chr(10);
	    raise notice '---------- %', chr(10);
	   
		raise notice '% % % % % % % % % % % % % % ', 
	   					format('%-20s','total_exec_time'), chr(9), 
	   					format('%-20s','ncalls'), chr(9), 
	   					format('%-20s','avg_exec_time_sec'), chr(9),
	   					format('%-20s','sync_io_time'), chr(9),
	   					format('%-20s','temp_blks_written'), chr(9),
	   					format('%-20s','queryid'), chr(9),
	   					'query', chr(10)   					
	   				; 
	   
	    FOR temp_query_cur IN
			select
			      interval '1 millisecond' * total_time as total_exec_time,
			      to_char(calls, 'FM999G999G999G990') as ncalls,
			      to_char((total_time / calls) / 1000, 'FM999G999G990.999') as avg_exec_time_sec,
			      interval '1 millisecond' * (blk_read_time + blk_write_time) as sync_io_time,
			      temp_blks_written,
			      queryid as queryid,
				  substring(replace(query, chr(10), ' '), 0, 200) as query
			from
				  epg_stats.get_stat_statements_hist(g_ts, g_interval)
			where
				temp_blks_written > 0
			order by
				temp_blks_written desc
			limit 10
	    loop
		    
			raise notice '% % % % % % % % % % % % % % ', 
		   					format('%-20s',temp_query_cur.total_exec_time), chr(9), 
		   					format('%-20s',temp_query_cur.ncalls), chr(9), 
		   					format('%-20s',temp_query_cur.avg_exec_time_sec), chr(9),
		   					format('%-20s',temp_query_cur.sync_io_time), chr(9),
		   					format('%-20s',temp_query_cur.temp_blks_written), chr(9),
		   					format('%-20s',temp_query_cur.queryid), chr(9),
		   					temp_query_cur.query, chr(10)   					
		   				; 	    	  
	    END LOOP;
	   
	   
	    raise notice '-------------------- % %', chr(10), chr(10);
	   
	    raise notice '---------- %', chr(10);
	    raise notice 'Top 10 Long Running Queries %', chr(10);
	    raise notice '---------- %', chr(10);
	   
		raise notice '% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %', 
	   					format('%-20s','ms_per_execution'), chr(9), 
	   					format('%-20s','ncalls'), chr(9), 
	   					format('%-20s','total_exec_time'), chr(9),
	   					format('%-20s','mean_time'), chr(9),
	   					format('%-20s','rrows'), chr(9),
	   					format('%-20s','shared_blks_hit'), chr(9),
	   					format('%-20s','shared_blks_read'), chr(9),
	   					format('%-20s','local_blks_hit'), chr(9),
	   					format('%-20s','local_blks_read'), chr(9),
	   					format('%-20s','temp_blks_read'), chr(9),
	   					format('%-20s','temp_blks_written'), chr(9),
	   					format('%-20s','blk_read_time'), chr(9),
	   					format('%-20s','blk_write_time'), chr(9),
	   					format('%-20s','userid'), chr(9),
	   					format('%-20s','queryid'), chr(9),
	   					'query', chr(10)   					
	   				;    
	      
	    FOR long_query_cur IN 
			select
				(interval '1 millisecond' * total_time) / calls as ms_per_execution,
				to_char(calls, 'FM999G999G999G990') as ncalls,
				interval '1 millisecond' * total_time as total_exec_time,
				mean_time,
				rows as rrows,
				shared_blks_hit,
				shared_blks_read,
				local_blks_hit,
				local_blks_read,
				temp_blks_read,
				temp_blks_written,
				blk_read_time,
				blk_write_time,
				userid,
				queryid,
				substring(replace(replace(query, chr(10), ' '), chr(13), ' '), 0, 200) as query
			from
				epg_stats.get_stat_statements_hist(g_ts,
				g_interval)
			order by
				total_time desc
			limit 10
	    loop
		    
			raise notice '% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %', 
	   					format('%-20s',long_query_cur.ms_per_execution), chr(9), 
	   					format('%-20s',long_query_cur.ncalls), chr(9), 
	   					format('%-20s',long_query_cur.total_exec_time), chr(9),
	   					format('%-20s',long_query_cur.mean_time), chr(9),
	   					format('%-20s',long_query_cur.rrows), chr(9),
	   					format('%-20s',long_query_cur.shared_blks_hit), chr(9),
	   					format('%-20s',long_query_cur.shared_blks_read), chr(9),
	   					format('%-20s',long_query_cur.local_blks_hit), chr(9),
	   					format('%-20s',long_query_cur.local_blks_read), chr(9),
	   					format('%-20s',long_query_cur.temp_blks_read), chr(9),
	   					format('%-20s',long_query_cur.temp_blks_written), chr(9),
	   					format('%-20s',long_query_cur.blk_read_time), chr(9),
	   					format('%-20s',long_query_cur.blk_write_time), chr(9),
	   					format('%-20s',long_query_cur.userid), chr(9),
	   					format('%-20s',long_query_cur.queryid), chr(9),
	   					long_query_cur.query, chr(10)   					
	   				;  	    	    
	    END LOOP;

   		raise notice '-------------------- % %' , chr(10), chr(10);

		raise notice '---------- %', chr(10);
	    raise notice 'Top 10 Most Executed Queries %', chr(10);
	    raise notice '---------- %', chr(10);
	   
		raise notice '% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %', 
	   					format('%-20s','ms_per_execution'), chr(9), 
	   					format('%-20s','ncalls'), chr(9), 
	   					format('%-20s','total_exec_time'), chr(9),
	   					format('%-20s','mean_time'), chr(9),
	   					format('%-20s','rrows'), chr(9),
	   					format('%-20s','shared_blks_hit'), chr(9),
	   					format('%-20s','shared_blks_read'), chr(9),
	   					format('%-20s','local_blks_hit'), chr(9),
	   					format('%-20s','local_blks_read'), chr(9),
	   					format('%-20s','temp_blks_read'), chr(9),
	   					format('%-20s','temp_blks_written'), chr(9),
	   					format('%-20s','blk_read_time'), chr(9),
	   					format('%-20s','blk_write_time'), chr(9),
	   					format('%-20s','userid'), chr(9),
	   					format('%-20s','queryid'), chr(9),
	   					'query', chr(10)   					
	   				;    
	      
	    FOR most_query_cur IN 
			select
				(interval '1 millisecond' * total_time) / calls as ms_per_execution,
				to_char(calls, 'FM999G999G999G990') as ncalls,
				interval '1 millisecond' * total_time as total_exec_time,
				mean_time,
				rows as rrows,
				shared_blks_hit,
				shared_blks_read,
				local_blks_hit,
				local_blks_read,
				temp_blks_read,
				temp_blks_written,
				blk_read_time,
				blk_write_time,
				userid,
				queryid,
				substring(replace(replace(query, chr(10), ' '), chr(13), ' '), 0, 200) as query
			from
				epg_stats.get_stat_statements_hist(g_ts,
				g_interval)
			order by
				calls desc
			limit 10
	    loop
		    
			raise notice '% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %', 
	   					format('%-20s',most_query_cur.ms_per_execution), chr(9), 
	   					format('%-20s',most_query_cur.ncalls), chr(9), 
	   					format('%-20s',most_query_cur.total_exec_time), chr(9),
	   					format('%-20s',most_query_cur.mean_time), chr(9),
	   					format('%-20s',most_query_cur.rrows), chr(9),
	   					format('%-20s',most_query_cur.shared_blks_hit), chr(9),
	   					format('%-20s',most_query_cur.shared_blks_read), chr(9),
	   					format('%-20s',most_query_cur.local_blks_hit), chr(9),
	   					format('%-20s',most_query_cur.local_blks_read), chr(9),
	   					format('%-20s',most_query_cur.temp_blks_read), chr(9),
	   					format('%-20s',most_query_cur.temp_blks_written), chr(9),
	   					format('%-20s',most_query_cur.blk_read_time), chr(9),
	   					format('%-20s',most_query_cur.blk_write_time), chr(9),
	   					format('%-20s',most_query_cur.userid), chr(9),
	   					format('%-20s',most_query_cur.queryid), chr(9),
	   					most_query_cur.query, chr(10)   					
	   				;  	    	    
	    END LOOP;
    end if;

   	raise notice '-------------------- % %' , chr(10), chr(10);
   
    raise notice '-------------------- %' , chr(10);
    raise notice 'Top 10 Bloated Tables %' , chr(10);
    raise notice '-------------------- %' , chr(10);
   
	raise notice '% % % % % % % % % % % % % %', 
   					format('%-30s','schema_name'), chr(9), 
   					format('%-60s','table_name') , chr(9),
					format('%-30s','n_dead_tup') , chr(9),
					format('%-30s','n_live_tup') , chr(9),
   					format('%-20s','bloat_ratio'), chr(9),
					format('%-30s','last_vacuum') , chr(9),
   					format('%-30s','last_autovacuum'), chr(10)			
   				;       

    FOR bloats_curr IN  	        
		select
			format('%-30s',schemaname) as schemaname,
			format('%-60s',relname) as relname,
		    format('%-30s',n_dead_tup) as n_dead_tup,
		    format('%-30s',n_live_tup) as n_live_tup,
		    format('%-20s',1-round(n_live_tup/cast(n_live_tup+n_dead_tup as numeric),2)) as bloat_ratio,
		    format('%-30s',last_autovacuum) as last_autovacuum,
		    format('%-30s',last_vacuum) as last_vacuum
		from
			epg_stats.get_stat_all_tables_hist(cast(extract(epoch from now()) as bigint),
			interval '1 hours')
		where
			schemaname not in ('pg_catalog', 'information_schema') and
			n_live_tup+n_dead_tup > 0
		order by 5 desc
		limit 10
    loop	    
	    raise notice '% % % % % % % % % % % % % % ', 
   					bloats_curr.schemaname, chr(9), 
   					format('%-30s',bloats_curr.relname), chr(9), 
   					format('%-60s',bloats_curr.n_dead_tup) , chr(9),
   					format('%-20s',bloats_curr.n_live_tup), chr(9),
   					format('%-20s',bloats_curr.bloat_ratio), chr(9),	
					format('%-20s',bloats_curr.last_vacuum), chr(9),
					format('%-20s',bloats_curr.last_autovacuum), chr(10)		
   				; 	    	    
    END LOOP;
   
    raise notice '-------------------- % %', chr(10), chr(10);
   
    raise notice '---------- %', chr(10);
    raise notice 'Top 20 Closest Tables to Wraparound (current) %', chr(10);
    raise notice '---------- %', chr(10);
    
   	raise notice '% % % % % % % % ', 
   					format('%-30s','schema_name'), chr(9),    					
   					format('%-60s','table_name') , chr(9),
   					format('%-20s','age'), chr(9),
   					format('%-20s','tablesize') , chr(10)			
   				;       
   
    FOR table_wraparound_curr IN 
		select
			n.oid::regclass as tablespacename,
			c.oid::regclass as tablename,
			age(c.relfrozenxid) as age,
			pg_size_pretty(pg_total_relation_size(c.oid)) as tablesize
		from
			pg_class c
		join pg_namespace n on
			c.relnamespace = n.oid
		where
			relkind in ('r', 't', 'm')
			and n.nspname not in ('pg_toast')
		order by
			3 desc
		limit 20
    loop
	    
	   	raise notice '% % % % % % % % ', 
				format('%-30s',table_wraparound_curr.tablespacename), chr(9),    					
				format('%-60s',table_wraparound_curr.tablename) , chr(9),
				format('%-20s',table_wraparound_curr.age) , chr(9),
				format('%-20s',table_wraparound_curr.tablesize) , chr(10)			
			;       
	    
    END LOOP;
   
    raise notice '-------------------- % %', chr(10), chr(10); 
   
/*
    raise notice '---------- %', chr(10);
    raise notice 'Top 20 Largest Tables (current) %', chr(10);
    raise notice '---------- %', chr(10);
   
   
	raise notice '% % % % % % ', 
   					format('%-30s','schema_name'), chr(9),    					
   					format('%-60s','relation_name') , chr(9),
   					format('%-20s','total_size') , chr(10)   							
   				; 
   
    FOR top_table_size_curr IN
        SELECT
            nspname AS "schema_name",
            relname AS "relation_name",
            pg_size_pretty (
                pg_total_relation_size (C .oid)
            ) AS "total_size"
        FROM
            pg_class C
        LEFT JOIN pg_namespace N ON (N.oid = C .relnamespace)
        WHERE
            nspname NOT IN (
                'pg_catalog',
                'information_schema'
            )
        AND C .relkind <> 'i'
        AND nspname !~ '^pg_toast'
        ORDER BY
            pg_total_relation_size (C .oid) DESC
        LIMIT 20
    loop
	    
	    raise notice '% % % % % % ', 
   					format('%-30s',top_table_size_curr.schema_name) , chr(9),    					
   					format('%-60s',top_table_size_curr.relation_name) , chr(9),
   					format('%-20s',top_table_size_curr.total_size), chr(10)   							
   				; 
   				    
    END LOOP;
   */

    raise notice '-------------------- % %', chr(10), chr(10);
    raise notice '---------- %', chr(10);
    raise notice 'General Parameters %', chr(10);
    raise notice '---------- %', chr(10);
   
   
   	raise notice '% % % % % % ', 
   					format('%-30s','name'), chr(9),    					
   					format('%-30s','setting') , chr(9),
   					format('%-60s','category') , chr(10)   							
   				; 
   			
    FOR general_params_curr IN
        SELECT name, setting, category FROM epg_stats.get_stat_settings_hist(g_ts, g_interval) where name in ('listen_address','port','max_connections','shared_buffers','wal_buffers',
                                                              'temp_buffers', 'maintenance_work_mem', 'autovacuum_work_mem','effective_cache_size',
                                                              'superuser_reserved_connections','authentication_timeout',
                                                              'update_process_title','cluster_name' )
    loop
	    
   		raise notice '% % % % % % ', 
   					format('%-30s',general_params_curr.name), chr(9),    					
   					format('%-30s',general_params_curr.setting) , chr(9),
   					format('%-60s',general_params_curr.category) , chr(10)   							
   				; 	    
	    
    END LOOP;
   
    raise notice '-------------------- % %', chr(10), chr(10);
    raise notice '---------- %', chr(10);
    raise notice 'Autovacuum Parameters  %', chr(10);
    raise notice '---------- %', chr(10);
   
   
    raise notice '% % % % % % ', 
   					format('%-30s','name'), chr(9),    					
   					format('%-30s','setting') , chr(9),
   					format('%-60s','category') , chr(10)   							
   				; 
   			   
    FOR autovacuum_params_curr IN
        SELECT name, setting, category FROM epg_stats.get_stat_settings_hist(g_ts, g_interval) where name in ( 'autovacuum_freeze_max_age','autovacuum_max_workers','autovacuum_naptime',
                                        'autovacuum_vacuum_cost_delay','maintenance_work_mem','vacuum_freeze_min_age',
                                        'autovacuum_vacuum_cost_limit','autovacuum_vacuum_cost_delay',
                                        'vacuum_cost_page_hit', 'vacuum_cost_page_miss', 'vacuum_cost_page_dirty',
                                        'autovacuum_vacuum_scale_factor','autovacuum_vacuum_treshold')
    loop
	   
	  raise notice '% % % % % % ', 
   					format('%-30s',autovacuum_params_curr.name), chr(9),    					
   					format('%-30s',autovacuum_params_curr.setting)  , chr(9),
   					format('%-60s',autovacuum_params_curr.category)  , chr(10)   							
   				;  
	    
    END LOOP;
   
    raise notice '-------------------- % %', chr(10), chr(10);
   
    raise notice '---------- %', chr(10); 
    raise notice 'Parallel Processes Parameters %', chr(10);
    raise notice '---------- %', chr(10); 
    
   
    raise notice '% % % % % % ', 
   					format('%-30s','name'), chr(9),    					
   					format('%-30s','setting') , chr(9),
   					format('%-60s','category') , chr(10)   							
   				; 
   
    FOR parallel_params_curr IN
        SELECT name, setting, category FROM epg_stats.get_stat_settings_hist(g_ts, g_interval) where name in ('max_worker_processes','max_parallel_workers','max_parallel_workers_per_gather',
                                                               'parallel_setup_cost','parallel_tuple_cost','min_parallel_table_scan_size','min_parallel_index_scan_size',
                                                               'force_parallel_mode','work_mem','maintenance_work_mem')
    loop
	    
	    raise notice '% % % % % % ', 
   					format('%-30s',parallel_params_curr.name), chr(9),    					
   					format('%-30s',parallel_params_curr.setting) , chr(9),
   					format('%-60s',parallel_params_curr.category), chr(10)   							
   				; 
   			
    END LOOP;
   
    	raise notice '-------------------- % %', chr(10), chr(10); 
    
    	raise notice '---------- %', chr(10);
    	raise notice 'WAL Parameters %', chr(10);
     	raise notice '---------- %', chr(10);
    
	    raise notice '% % % % % % ', 
	   					format('%-30s','name'), chr(9),    					
	   					format('%-30s','setting') , chr(9),
	   					format('%-60s','category') , chr(10)   							
	   				; 
   			
    FOR wal_params_curr IN
        SELECT name, setting, category FROM epg_stats.get_stat_settings_hist(g_ts, g_interval)
          where name in ('fsync','wal_sync_method','synchronous_commit','wal_writer_delay', 'wal_writer_delay', 'wal_writer_flush_after',
                 'checkpoint_timeout','checkpoint_completion_target','checkpoint_flush_after','max_wal_size','commit_delay',
                 'wal_recycle','wal_compression','full_page_writes','wal_level','wal_buffers')
    loop
	    
	    raise notice '% % % % % % ', 
				format('%-30s',wal_params_curr.name), chr(9),    					
				format('%-30s',wal_params_curr.setting) , chr(9),
				format('%-60s',wal_params_curr.category) , chr(10)   							
			; 
	   				    
    END LOOP;
   
    raise notice '-------------------- % %', chr(10), chr(10);     

END;
$procedure$
;

