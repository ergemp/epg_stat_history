-- DROP FUNCTION epg_stats.get_series_archiver_hist(int8, interval);

CREATE OR REPLACE FUNCTION epg_stats.get_series_archiver_hist(g_ts bigint, g_interval interval)
 RETURNS TABLE(begin_ts bigint, end_ts bigint, archived_count bigint, last_archived_wal text, last_archived_time timestamp with time zone, failed_count bigint, last_failed_wal text, last_failed_time timestamp with time zone, stats_reset timestamp with time zone)
 LANGUAGE plpgsql
AS $function$
declare 
  c1 REFCURSOR;
  row_data RECORD;
begin
	CREATE TEMP TABLE IF NOT EXISTS temp_get_series_archiver_hist_results (
		begin_ts bigint, 
		end_ts bigint, 
		archived_count bigint, 
		last_archived_wal text, 
		last_archived_time timestamp with time zone, 
		failed_count bigint, 
		last_failed_wal text, 
		last_failed_time timestamp with time zone, 
		stats_reset timestamp with time zone
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
      insert into temp_get_series_archiver_hist_results
	    select 
	      min(sah.ts), max(sah.ts), 
	      max(sah.archived_count) - min(sah.archived_count) AS archived_count,
	      max(sah.last_archived_wal),
	      max(sah.last_archived_time),
	      max(sah.failed_count) - min(sah.failed_count) AS failed_count,
	      max(sah.last_failed_wal),
	      max(sah.last_failed_time),
	      max(sah.stats_reset)      
	    from 
	      epg_stats.stat_archiver_hist  sah
	    WHERE sah.ts IN (row_data.current_snapshot, row_data.previous_snapshot);
		/*
		select
			*
		from
			epg_stats.get_stat_archiver_hist(row_data.current_snapshot, row_data.iinterval);
		*/
    END LOOP;
    CLOSE c1;

	return query
	select * from temp_get_series_archiver_hist_results;

	drop table if exists temp_get_series_archiver_hist_results;
end;
$function$
;
