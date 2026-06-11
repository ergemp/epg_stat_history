drop procedure if exists epg_stats.drop_meta();

CREATE OR REPLACE PROCEDURE epg_stats.drop_meta()
 LANGUAGE plpgsql
AS $procedure$
declare 
begin 
	execute 'drop table if exists epg_stats.stat_all_tables_hist';
	execute 'drop table if exists epg_stats.stat_all_indexes_hist';
	execute 'drop table if exists epg_stats.statio_all_tables_hist';
	execute 'drop table if exists epg_stats.statio_all_indexes_hist';
	execute 'drop table if exists epg_stats.stat_activity_hist';
	execute 'drop table if exists epg_stats.stat_statements_hist';
	execute 'drop table if exists epg_stats.stat_archiver_hist';
	execute 'drop table if exists epg_stats.stat_bgwriter_hist';
	execute 'drop table if exists epg_stats.stat_checkpointer_hist';
	execute 'drop table if exists epg_stats.stat_locks_hist';
	execute 'drop table if exists epg_stats.stat_database_hist';
	execute 'drop table if exists epg_stats.pg_settings_hist';
	execute 'drop table if exists epg_stats.stat_intervals';
    execute 'drop table if exists epg_stats.stat_wal_hist';
end
$procedure$
;