-- DROP FUNCTION epg_stats.get_series_database_hist(int8, interval);

CREATE OR REPLACE FUNCTION epg_stats.get_series_database_hist(g_ts bigint, g_interval interval)
 RETURNS TABLE(begin_ts bigint, end_ts bigint, datid oid, datname character varying, numbackends integer, xact_commit bigint, xact_rollback bigint, blks_read bigint, blks_hit bigint, tup_returned bigint, tup_fetched bigint, tup_inserted bigint, tup_updated bigint, tup_deleted bigint, conflicts bigint, temp_files bigint, temp_bytes bigint, deadlocks bigint, checksum_failures bigint, checksum_last_failure timestamp with time zone, blk_read_time double precision, blk_write_time double precision, stats_reset timestamp with time zone)
 LANGUAGE plpgsql
AS $function$
declare 
  c1 REFCURSOR;
  row_data RECORD;
begin
    CREATE TEMP TABLE IF NOT EXISTS temp_results (
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
	  ts_timestamp,
	  ts_epoch as current_snapshot,
	  lag(ts_epoch) OVER (ORDER BY ts_epoch) AS previous_snapshot
	from epg_stats.find_interval_snapshots(g_ts, g_interval) order by 1 desc;

    LOOP
      FETCH c1 INTO row_data;
      EXIT WHEN NOT FOUND;
      -- raise notice '%', row_data.ts_timestamp;
      insert into temp_results
        select * from epg_stats.get_stat_database_hist(row_data.current_snapshot, (to_timestamp(row_data.current_snapshot)-to_timestamp(row_data.previous_snapshot))::interval);    
    END LOOP;
    CLOSE c1;

	return query
	select * from temp_results;
end;
$function$
;

