drop procedure if exists epg_stats.drop_meta();

create or replace procedure epg_stats.drop_meta()  as
$$
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
	execute 'drop table if exists epg_stats.stat_locks_hist';
	execute 'drop table if exists epg_stats.stat_database_hist';
	execute 'drop table if exists epg_stats.pg_settings_hist';
end
$$
language plpgsql 