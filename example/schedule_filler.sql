
--
-- scheduling pg_cron job
--
insert into cron.job 
(
jobid,
schedule,
command,
nodename,
nodeport,
database,
username,
active,
jobname
)
values
(
4,
'5/5 * * * *',
'call fv_stats.fill_meta();',
'localhost',
'5432',
'ergemp',
'postgres',
true,
'fv_stats_filler'
)
;


call epg_stats.fill_meta();

update cron.job set jobid=5 where jobid=4;

update cron.job set database='postgres' where jobid=5;
update cron.job set schedule='15,30,45,00 * * * *' where jobid=5;

select * from cron.job;
select * from cron.job_run_details order by runid desc;

--disable a job
update cron.job set active=false where jobid=5;


--
-- desc 
--
select column_name || ' ' || data_type || ',' from information_schema."columns"  where table_name = 'stat_statements_hist' order by ordinal_position asc;

--
-- work on epoch end datetime
--
select now();
select extract(epoch from now());

select to_timestamp(max(ts)), max(ts) from epg_stats.stat_activity_hist; 
select distinct to_timestamp(ts), ts from epg_stats.stat_activity_hist order by to_timestamp(ts) desc;


select to_timestamp(ts), ts from epg_stats.stat_activity_hist where ts >= 1606199201 order by ts asc limit 1;
select to_timestamp(ts), ts from epg_stats.stat_activity_hist where ts >= 1606199201 order by ts asc limit 1; 
select to_timestamp(ts), ts from epg_stats.stat_activity_hist where ts <= 1606199201 order by ts desc limit 1;

select extract(epoch from now());
select now(), (now()-interval '1 hour');

--
-- test find_between and find_interval
--
select * from epg_stats.stat_activity_hist where ts in (select ts_epoch from epg_stats.stat_intervals);
select * from epg_stats.stat_all_tables_hist;

select ts, to_timestamp(ts) from epg_stats.find_interval_boundaries(cast(extract (epoch from now()) as bigint),interval '1 day');
/*
1778487774	2026-05-11 11:22:54.000 +0300
1778495815	2026-05-11 13:36:55.000 +0300
*/

select ts_timestamp, ts_epoch from epg_stats.find_interval_snapshots(cast(extract (epoch from now()) as bigint),interval '1 day');
/*
2026-05-11 13:36:55.000	1778495815
2026-05-11 13:31:20.000	1778495480
2026-05-11 13:26:45.000	1778495205
2026-05-11 13:14:57.000	1778494497
2026-05-11 13:07:51.000	1778494071
2026-05-11 13:00:12.000	1778493612
2026-05-11 12:55:15.000	1778493315
2026-05-11 12:50:56.000	1778493056
2026-05-11 12:46:19.000	1778492779
2026-05-11 12:41:20.000	1778492480
2026-05-11 12:35:38.000	1778492138
2026-05-11 12:24:06.000	1778491446
2026-05-11 12:19:49.000	1778491189
2026-05-11 12:13:22.000	1778490802
2026-05-11 12:05:23.000	1778490323
2026-05-11 12:00:48.000	1778490048
2026-05-11 11:54:01.000	1778489641
2026-05-11 11:43:45.000	1778489025
2026-05-11 11:30:11.000	1778488211
2026-05-11 11:25:33.000	1778487933
2026-05-11 11:22:54.000	1778487774
*/

select extract (epoch from to_timestamp('2020-11-24 10:00','YYYY-MM-DD HH:MI'))

--
-- test getter functions
--  

select * from epg_stats.get_stat_settings_hist(cast(extract(epoch from now()) as bigint), interval '30 min') ;


select count(*) from 
(
  select * from epg_stats.stat_activity_hist sah where sah.ts <= cast(extract(epoch from now()) as bigint) limit 1
) as cnt;

select max(sah.ts), to_timestamp(max(sah.ts)) FROM epg_stats.stat_activity_hist sah WHERE sah.ts < (select max(ts) from epg_stats.stat_activity_hist );
  

select * from epg_stats.get_stat_statements_hist(1606199201, interval '1 hour') order by total_time desc ;  
select * from epg_stats.get_stat_statements_hist(1606199201, interval '1 hour') where queryid=-976633341077716839 order by total_time desc ;
select * from epg_stats.stat_statements_hist ssh  where ssh.ts = 1606199201 and ssh.queryid=-976633341077716839;
select * from epg_stats.stat_statements_hist ssh  where ssh.ts = 1606199201 and ssh.queryid=-976633341077716839;


select * from epg_stats.get_stat_all_tables_hist(1606199201,INTERVAL '20 mins') ;
select * from epg_stats.get_statio_all_tables_hist(1606199201,INTERVAL '20 mins') ;
select * from epg_stats.get_stat_all_indexes_hist(1606199201,INTERVAL '20 mins');
select * from epg_stats.get_statio_all_indexes_hist(1606199201,INTERVAL '20 mins');
select * from epg_stats.get_stat_database_hist(1606199201,INTERVAL '20 mins') ;
select * from epg_stats.get_stat_bgwriter_hist(1606199201,INTERVAL '20 mins') ;
select * from epg_stats.get_stat_archiver_hist(1606199201,INTERVAL '20 mins') ;
select * from epg_stats.get_stat_locks_hist(1606199201,INTERVAL '20 mins') ;
select * from epg_stats.get_stat_statements_hist(1606199201,INTERVAL '20 mins') ;
select * from epg_stats.get_stat_activity_hist(1606199201,INTERVAL '20 mins') ;

SELECT 
  to_timestamp(begin_ts), to_timestamp(end_ts), * 
FROM epg_stats.get_stat_all_tables_hist(1606223700, interval '30 min') order by seq_scan desc

SELECT 
  to_timestamp(begin_ts), to_timestamp(end_ts), * 
FROM epg_stats.get_stat_all_indexes_hist(1606223700, interval '30 min') ;

select 
  to_timestamp(ts), * 
from epg_stats.get_stat_activity_hist(cast(extract (epoch from now()- interval '2 hour') as bigint),INTERVAL '30 mins') ;

select * from epg_stats.stat_bgwriter_hist sbh where ts = 1606197600

