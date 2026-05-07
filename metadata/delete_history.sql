-- DROP PROCEDURE epg_stats.delete_history(interval);

CREATE OR REPLACE PROCEDURE epg_stats.delete_history(IN g_interval interval)
 LANGUAGE plpgsql
AS $procedure$
declare 
  nnow timestamp with time zone := now()::timestamp with time zone;
begin 	    
    delete from epg_stats.stat_activity_hist where ts < cast(extract (epoch from nnow - g_interval) as bigint);
    delete from epg_stats.stat_all_indexes_hist where ts < cast(extract (epoch from nnow - g_interval) as bigint);
    delete from epg_stats.stat_all_tables_hist where ts < cast(extract (epoch from nnow - g_interval) as bigint);
    delete from epg_stats.statio_all_tables_hist where ts < cast(extract (epoch from nnow - g_interval) as bigint);
    delete from epg_stats.statio_all_indexes_hist where ts < cast(extract (epoch from nnow - g_interval) as bigint);
    delete from epg_stats.stat_statements_hist where ts < cast(extract (epoch from nnow - g_interval) as bigint);
    delete from epg_stats.stat_locks_hist where ts < cast(extract (epoch from nnow - g_interval) as bigint);
    delete from epg_stats.stat_database_hist where ts < cast(extract (epoch from nnow - g_interval) as bigint);
    delete from epg_stats.stat_bgwriter_hist where ts < cast(extract (epoch from nnow - g_interval) as bigint);
    delete from epg_stats.stat_checkpointer_hist where ts < cast(extract (epoch from nnow - g_interval) as bigint);
    delete from epg_stats.stat_archiver_hist where ts < cast(extract (epoch from nnow - g_interval) as bigint);
    delete from epg_stats.pg_settings_hist where ts < cast(extract (epoch from nnow - g_interval) as bigint);
	delete from epg_stats.stat_intervals where ts_epoch < cast(extract (epoch from nnow - g_interval) as bigint);
end
$procedure$
;

--call fv_stats.delete_history(interval '10 minute' );