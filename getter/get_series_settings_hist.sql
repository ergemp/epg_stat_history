-- DROP FUNCTION epg_stats.get_series_settings_hist(int8, interval);

CREATE OR REPLACE FUNCTION epg_stats.get_series_settings_hist(g_ts bigint, g_interval interval)
 RETURNS TABLE(ts bigint, name text, setting text, category text)
 LANGUAGE plpgsql
AS $function$
declare 
  c1 REFCURSOR;
  row_data RECORD;
begin

	--drop table if exists temp_get_series_settings_hist_results; 

    CREATE TEMP TABLE IF NOT EXISTS temp_get_series_settings_hist_results (
		ts bigint, 
		name text, 
		setting text, 
		category text
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
      insert into temp_get_series_settings_hist_results
	    select 
	      psh.ts, psh.name, psh.setting, psh.category
	    from 
	      epg_stats.pg_settings_hist  psh
	    WHERE psh.ts = row_data.previous_snapshot
	    ;  
    END LOOP;
    CLOSE c1;

	return query
	select * from temp_get_series_settings_hist_results;

	drop table if exists temp_get_series_settings_hist_results;

end;
$function$
;
