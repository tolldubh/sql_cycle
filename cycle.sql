CREATE TABLE `cycle` (
  `flow` int DEFAULT NULL,
  `cycle_date` date NOT NULL,
  `cycle_id` int NOT NULL,
  PRIMARY KEY (`cycle_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
