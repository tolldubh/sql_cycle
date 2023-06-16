create view health.cycle_day1 as (
select c.cycle_id, c.cycle_date from health.cycle c
left outer join health.cycle c2
on c.cycle_date = date_add(c2.cycle_date, interval 1 day)
where c2.cycle_date is null);

create view health.cycle_duration as (
    SELECT
    t1.cycle_date,
    DATEDIFF(
        t1.cycle_date,
        (SELECT MAX(t2.cycle_date) FROM health.cycle_day1 t2 WHERE t2.cycle_date < t1.cycle_date)
    ) AS days_since_previous
FROM
    health.cycle_day1 t1
ORDER BY
    t1.cycle_date);
    
create view health.cycle_next_expected as (
select date_add(max(cycle_date),interval (select avg(days_since_previous) from health.cycle_duration) day) as next_expected
from health.cycle_day1);
 
create view health.cycle_avg_days as (
with days as (
select count(*) as days from health.cycle
where cycle_id not in (select max(cycle_id) from health.cycle)
group by cycle_id)
select avg(days) as avg_days from days)
;