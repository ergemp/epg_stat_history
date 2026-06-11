-- DROP FUNCTION epg_stats.get_series_database_hist(int8, interval);

CREATE OR REPLACE FUNCTION epg_stats.get_series_database_hist(g_ts bigint, g_interval interval)
 RETURNS TABLE(begin_ts bigint, end_ts bigint, datid oid, datname character varying, numbackends integer, xact_commit bigint, xact_rollback bigint, blks_read bigint, blks_hit bigint, tup_returned bigint, tup_fetched bigint, tup_inserted bigint, tup_updated bigint, tup_deleted bigint, conflicts bigint, temp_files bigint, temp_bytes bigint, deadlocks bigint, checksum_failures bigint, checksum_last_failure timestamp with time zone, blk_read_time double precision, blk_write_time double precision, stats_reset timestamp with time zone)
 LANGUAGE plpgsql
AS $function$
declare 
  c1 REFCURSOR;
  row_data RECORD;
begin
    CREATE TEMP TABLE IF NOT EXISTS temp_get_series_database_hist_results (
		begin_ts int8 NULL,
		end_ts int8 NULL,
		datid oid NULL,
		datname varchar(100) NULL,
		numbackends int4 NULL,
		xact_commit int8 NULL,
		xact_rollback int8 NULL,
		blks_read int8 NULL,
		blks_hit int8 NULL,
		tup_returned int8 NULL,
		tup_fetched int8 NULL,
		tup_inserted int8 NULL,
		tup_updated int8 NULL,
		tup_deleted int8 NULL,
		conflicts int8 NULL,
		temp_files int8 NULL,
		temp_bytes int8 NULL,
		deadlocks int8 NULL,
		checksum_failures int8 NULL,
		checksum_last_failure timestamptz NULL,
		blk_read_time float8 NULL,
		blk_write_time float8 NULL,
		stats_reset timestamptz NULL
    ) ON COMMIT DROP;

  open c1 for
	select
		to_timestamp(current_snapshot),
		to_timestamp(previous_snapshot),
		current_snapshot,
		previous_snapshot,
		(date_trunc('minute', to_timestamp(current_snapshot))-date_trunc('minute',to_timestamp(previous_snapshot)))::interval as iinterval
	from
		(
		select
			ts_timestamp,
			ts_epoch as current_snapshot,
			lag(ts_epoch) over (
			order by ts_epoch) as previous_snapshot
		from
			epg_stats.find_interval_snapshots(g_ts, g_interval )
		order by
			1 desc
		)t
	where
		previous_snapshot is not null;

    LOOP
      FETCH c1 INTO row_data;
      EXIT WHEN NOT FOUND;
      -- raise notice '%', row_data.ts_timestamp;
      insert into temp_get_series_database_hist_results
		select 
	      min(sdh.ts) as begin_ts, 
	      max(sdh.ts) as end_ts, 
	      sdh.datid, sdh.datname,
	      max(sdh.numbackends) - coalesce(min(sdh.numbackends),0) AS numbackends,
	      max(sdh.xact_commit) - coalesce(min(sdh.xact_commit),0) AS xact_commit,
	      max(sdh.xact_rollback) - coalesce(min(sdh.xact_rollback),0) AS xact_rollback,
	      max(sdh.blks_read) - coalesce(min(sdh.blks_read),0) AS blks_read,
	      max(sdh.blks_hit) - coalesce(min(sdh.blks_hit),0) AS blks_hit,
	      max(sdh.tup_returned) - coalesce(min(sdh.tup_returned),0) AS tup_returned,
	      max(sdh.tup_fetched) - coalesce(min(sdh.tup_fetched),0) AS tup_fetched,
	      max(sdh.tup_inserted) - coalesce(min(sdh.tup_inserted),0) AS tup_inserted,
	      max(sdh.tup_updated) - coalesce(min(sdh.tup_updated),0) AS tup_updated,
	      max(sdh.tup_deleted) - coalesce(min(sdh.tup_deleted),0) AS tup_deleted,      
	      max(sdh.conflicts) - coalesce(min(sdh.conflicts),0) AS conflicts,      
	      max(sdh.temp_files) - coalesce(min(sdh.temp_files),0) AS temp_files,      
	      max(sdh.temp_bytes) - coalesce(min(sdh.temp_bytes),0) AS temp_bytes,      
	      max(sdh.deadlocks) - coalesce(min(sdh.deadlocks),0) AS deadlocks,      
	      max(sdh.checksum_failures) - coalesce(min(sdh.checksum_failures),0) AS checksum_failures,      
	      max(sdh.checksum_last_failure),      
	      max(sdh.blk_read_time) - coalesce(min(sdh.blk_read_time),0) AS blk_read_time,      
	      max(sdh.blk_write_time) - coalesce(min(sdh.blk_write_time),0) AS blk_write_time,      
	      max(sdh.stats_reset)      
	    from 
	      epg_stats.stat_database_hist  sdh
	      where sdh.ts in (row_data.current_snapshot, row_data.previous_snapshot)
		group by sdh.datid, sdh.datname;
    END LOOP;
    CLOSE c1;

	return query
	select * from temp_get_series_database_hist_results;

    drop table if exists temp_get_series_database_hist_results;
end;
$function$
;
