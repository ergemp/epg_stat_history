-- DROP FUNCTION epg_stats.get_series_settings_hist(int8, interval);

CREATE OR REPLACE FUNCTION epg_stats.get_series_settings_hist(g_ts bigint, g_interval interval)
 RETURNS TABLE(ts bigint, name text, setting text, category text)
 LANGUAGE plpgsql
AS $function$
declare 
  c1 REFCURSOR;
  row_data RECORD;
begin

	drop table if exists temp_results; 

    CREATE TEMP TABLE IF NOT EXISTS temp_results (
		ts bigint, 
		name text, 
		setting text, 
		category text
    ) ON COMMIT DROP;

  open c1 for
	select * from 
	(
	select 
	  ts_timestamp,
	  ts_epoch as current_snapshot,
	  lag(ts_epoch) OVER (ORDER BY ts_epoch) AS previous_snapshot
	from epg_stats.find_interval_snapshots(cast(extract(epoch from now()) as bigint), '1 day'::interval) order by 1 desc
	)
	where previous_snapshot is not null; 

    LOOP
      FETCH c1 INTO row_data;
      EXIT WHEN NOT FOUND;
      -- raise notice '%', row_data.ts_timestamp;
      insert into temp_results
        select * from epg_stats.get_stat_settings_hist(row_data.current_snapshot, (to_timestamp(row_data.current_snapshot)-to_timestamp(row_data.previous_snapshot))::interval);    
    END LOOP;
    CLOSE c1;

	return query
	select * from temp_results;
end;
$function$
;
