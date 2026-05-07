-- DROP FUNCTION epg_stats.get_series_checkpointer_hist(int8, interval);

CREATE OR REPLACE FUNCTION epg_stats.get_series_checkpointer_hist(g_ts bigint, g_interval interval)
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
declare 
  c1 REFCURSOR;
  row_data RECORD;
begin
	CREATE TEMP TABLE IF NOT EXISTS temp_results (
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
	 	stats_reset timestamp with time zone
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
        select * from epg_stats.get_stat_checkpointer_hist(row_data.current_snapshot, (to_timestamp(row_data.current_snapshot)-to_timestamp(row_data.previous_snapshot))::interval);    
    END LOOP;
    CLOSE c1;

	return query
	select * from temp_results;
end;
$function$
;