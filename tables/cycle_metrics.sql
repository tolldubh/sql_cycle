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