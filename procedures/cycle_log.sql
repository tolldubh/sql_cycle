create PROCEDURE health.cycle_log
    (@cycle_date DATE,
    @flow INT
    )
AS
BEGIN
    DECLARE @cycle_id int
    SELECT @cycle_id = MAX(CASE
               WHEN DATEDIFF(day, cycle_next_expected, GETDATE()) BETWEEN -7 AND 7
               THEN cycle_id + 1
               ELSE cycle_id
           END)
            FROM health.cycle_metrics;

    INSERT INTO health.cycle
        (cycle_id, cycle_date, flow)
    VALUES
        (@cycle_id, @cycle_date, @flow);

EXEC health.calculate_cycle;

END;
GO