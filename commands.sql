/* The point of this table is to have cumulative metrics for cycle
tracking: what has been the trend so far, and how far have you
deviated from your normal? It makes outliers easier to spot (pun
intended).
*/

CREATE TABLE cycle_metrics (
  cycle_id INT NOT NULL,
  cycle_duration INT NULL,
  period_duration INT NULL,
  cycle_next_expected DATE NULL,
  cycle_next_actual DATE NULL,
  cycle_duration_avg INT NULL,
  period_duration_avg INT NULL,
  start_date DATE NULL,
  end_date DATE NULL,
  days_off INT NULL,
  period_days_off INT NULL,
  PRIMARY KEY (cycle_id),
  UNIQUE (cycle_id)
);

-- initial values
MERGE INTO health.cycle_metrics AS target
USING (SELECT cycle_id, COUNT(*) AS period_duration
       FROM health.cycle
       GROUP BY cycle_id) AS source
ON target.cycle_id = source.cycle_id
WHEN MATCHED THEN
    UPDATE SET target.period_duration = source.period_duration
WHEN NOT MATCHED THEN
    INSERT (cycle_id, period_duration)
    VALUES (source.cycle_id, source.period_duration);

-- add start_date
UPDATE cm
SET cm.start_date = cd.cycle_date
FROM health.cycle_metrics cm
INNER JOIN health.cycle_day1 cd ON cd.cycle_id = cm.cycle_id;

-- add cycle_duration
WITH days_until AS (
    SELECT
        t1.cycle_id,
        DATEDIFF(
            DAY, -- Specify the date part (DAY)
            (SELECT MIN(t2.cycle_date) FROM health.cycle_day1 t2 WHERE t2.cycle_date > t1.cycle_date),
            t1.cycle_date
        ) * -1 AS days_until_next
    FROM
        health.cycle_day1 t1
)
UPDATE cm
SET cm.cycle_duration = du.days_until_next
FROM
    health.cycle_metrics cm
    INNER JOIN days_until du ON du.cycle_id = cm.cycle_id;

-- add cycle_next_actual
UPDATE health.cycle_metrics
SET cycle_next_actual = DATEADD(day, cycle_duration, start_date);

-- get cumulative average cycle length for each month
WITH average AS (
  SELECT cm.cycle_id, AVG(cm2.cycle_duration) AS avg_cycle_duration
  FROM health.cycle_metrics cm
  INNER JOIN health.cycle_metrics cm2 ON cm.cycle_id >= cm2.cycle_id
  GROUP BY cm.cycle_id
)
UPDATE cm
SET cm.cycle_duration_avg = a.avg_cycle_duration
FROM health.cycle_metrics cm
INNER JOIN average a ON cm.cycle_id = a.cycle_id;

-- add the date when the next cycle should start, based on the cumulative average
UPDATE health.cycle_metrics
SET cycle_next_expected = DATEADD(day, cycle_duration_avg, start_date);

-- get cumulative average period length for each month
WITH average AS (
  SELECT cm.cycle_id, AVG(cm2.period_duration) AS avg_period_duration
  FROM health.cycle_metrics cm
  INNER JOIN health.cycle_metrics cm2 ON cm.cycle_id >= cm2.cycle_id
  GROUP BY cm.cycle_id
)
UPDATE cm
SET cm.period_duration_avg = a.avg_period_duration
FROM health.cycle_metrics cm
INNER JOIN average a ON cm.cycle_id = a.cycle_id;

-- add end_date
UPDATE health.cycle_metrics
SET end_date = DATEADD(day, -1, cycle_next_actual);

-- add the difference between cycle_next_expected and cycle_next_actual
UPDATE health.cycle_metrics
SET days_off = DATEDIFF(day, cycle_next_expected, cycle_next_actual);

-- add difference between actual period days and average period days
UPDATE health.cycle_metrics
SET period_days_off = period_duration - period_duration_avg;

select * from health.cycle;