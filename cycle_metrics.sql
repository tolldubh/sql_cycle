/* The point of this table is to have cumulative metrics for cycle
tracking: what has been the trend so far, and how far have you
deviated from your normal? It makes outliers easier to spot (pun
intended).
*/

CREATE TABLE `cycle_metrics` (
  `cycle_id` int NOT NULL,
  `cycle_duration` int DEFAULT NULL,
  `period_duration` int DEFAULT NULL,
  `cycle_next_expected` date DEFAULT NULL,
  `cycle_next_actual` date DEFAULT NULL,
  `cycle_duration_avg` int DEFAULT NULL,
  `period_duration_avg` int DEFAULT NULL,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `days_off` int DEFAULT NULL,
  `period_days_off` int DEFAULT NULL,
  PRIMARY KEY (`cycle_id`),
  UNIQUE KEY `cycle_id_UNIQUE` (`cycle_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- initial values
INSERT INTO health.cycle_metrics (cycle_id, period_duration)
SELECT cycle_id, period_duration
from (SELECT cycle_id, count(*) as period_duration
from health.cycle
group by cycle_id) duration
on duplicate key update period_duration = duration.period_duration;


-- add start_date
update health.cycle_metrics cm
inner join health.cycle_day1 cd
on cd.cycle_id = cm.cycle_id
set cm.start_date = cd.cycle_date;
;

-- add cycle_duration
with days_until as (
SELECT t1.cycle_id,
    DATEDIFF(
        t1.cycle_date,
        ((SELECT min(t2.cycle_date) FROM health.cycle_day1 t2 WHERE t2.cycle_date > t1.cycle_date)
    )) * -1 AS days_until_next
FROM
    health.cycle_day1 t1
ORDER BY
    t1.cycle_date)
update health.cycle_metrics cm
inner join days_until du
on du.cycle_id = cm.cycle_id
set cm.cycle_duration = du.days_until_next;

-- add cycle_next_actual
update health.cycle_metrics set cycle_next_actual = date_add(start_date, interval cycle_duration day);

-- get cumulative average cycle length for each month
with average as 
(select cm.cycle_id, avg(cm2.cycle_duration) as avg_cycle_duration
from health.cycle_metrics cm
inner join health.cycle_metrics cm2
on cm.cycle_id >= cm2.cycle_id
group by cm.cycle_id)
update health.cycle_metrics cm
inner join average a
on cm.cycle_id = a.cycle_id
set cm.cycle_duration_avg = a.avg_cycle_duration;

-- add the date when the next cycle should start, based on the cumulative average
update health.cycle_metrics cm
set cm.cycle_next_expected = date_add(start_date, interval cycle_duration_avg day);

-- get cumulative average period length for each month
with average as 
(select cm.cycle_id, avg(cm2.period_duration) as avg_period_duration
from health.cycle_metrics cm
inner join health.cycle_metrics cm2
on cm.cycle_id >= cm2.cycle_id
group by cm.cycle_id)
update health.cycle_metrics cm
inner join average a
on cm.cycle_id = a.cycle_id
set cm.period_duration_avg = a.avg_period_duration;

-- add end_date
update health.cycle_metrics cm
set cm.end_date = date_add(cycle_next_actual, interval -1 day);

-- add the difference between cycle_next_expected and cycle_next_actual
update health.cycle_metrics cm
set cm.days_off = datediff(cycle_next_actual, cycle_next_expected);

-- add difference between actual period days and average period days
update health.cycle_metrics set period_days_off = period_duration - period_duration_avg;

commit;
