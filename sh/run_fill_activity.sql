do
$$
declare
  i_ctl int;
begin
  i_ctl := 0; 
  while i_ctl<10 loop
    --raise notice '%', clock_timestamp(); 
    call epg_stats.fill_activity();
    commit;
    perform pg_sleep(5);  
    --i_ctl := i_ctl+1;
  end loop; 
end;
$$