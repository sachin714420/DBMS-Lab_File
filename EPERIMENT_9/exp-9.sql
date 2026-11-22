/* ============================================================================
   DBMS LAB - EXPERIMENT 9
   TITLE: DATABASE INDEXING AND QUERY EXECUTION PLAN BENCHMARKING
   DBMS: MySQL 8.0+

   AIM
   ---
   To create a Railway Booking table containing at least 5,000 records,
   benchmark query performance before and after creating single-column and
   composite indexes, and use EXPLAIN to compare execution plans.

   BEFORE YOU RUN
   --------------
   1. Execute this file from top to bottom in MySQL Workbench or a compatible tool.
   2. This script automatically creates RailwayDB and generates 6,000 rows.
   3. Compare EXPLAIN and EXPLAIN ANALYZE outputs across Stages 1, 2, and 3.

   TABLES USED
   -----------
   Railway_Booking(booking_id, passenger_name, train_no, source_station,
                   destination_station, journey_date, travel_class, seat_no,
                   fare, booking_status)
   ============================================================================ */

CREATE DATABASE IF NOT EXISTS RailwayDB;
USE RailwayDB;

/* ---------------------------------------------------------------------------
   STEP 1: CREATE THE RAILWAY_BOOKING TABLE
   PURPOSE: Define the schema for storing 6,000 railway reservation records.
   KEY IDEA: Only booking_id has a PRIMARY KEY clustered index initially.
   --------------------------------------------------------------------------- */
DROP TABLE IF EXISTS Railway_Booking;
CREATE TABLE Railway_Booking (
    booking_id INT PRIMARY KEY,
    passenger_name VARCHAR(50) NOT NULL,
    train_no INT NOT NULL,
    source_station VARCHAR(30) NOT NULL,
    destination_station VARCHAR(30) NOT NULL,
    journey_date DATE NOT NULL,
    travel_class VARCHAR(5),
    seat_no INT,
    fare DECIMAL(8,2),
    booking_status VARCHAR(15)
);

/* ---------------------------------------------------------------------------
   STEP 2: INSERT 6,000 RECORDS USING RECURSIVE CTE
   PURPOSE: Generate 6,000 synthetic bookings across 50 trains, 365 dates,
            10 stations, 5 travel classes, and 3 booking statuses.
   --------------------------------------------------------------------------- */
SET SESSION cte_max_recursion_depth = 10000;

INSERT INTO Railway_Booking (
    booking_id,
    passenger_name,
    train_no,
    source_station,
    destination_station,
    journey_date,
    travel_class,
    seat_no,
    fare,
    booking_status
)
WITH RECURSIVE seq AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 6000
)
SELECT
    n,
    CONCAT('Passenger_', n),
    12000 + MOD(n * 7, 50),
    ELT(MOD(n, 10) + 1,
        'Delhi', 'Mumbai', 'Kolkata', 'Chennai', 'Lucknow',
        'Kanpur', 'Jaipur', 'Bhopal', 'Patna', 'Ahmedabad'),
    ELT(MOD(n * 3 + 1, 10) + 1,
        'Delhi', 'Mumbai', 'Kolkata', 'Chennai', 'Lucknow',
        'Kanpur', 'Jaipur', 'Bhopal', 'Patna', 'Ahmedabad'),
    DATE_ADD('2026-01-01', INTERVAL MOD(n, 365) DAY),
    ELT(MOD(FLOOR(n / 7), 5) + 1, 'SL', '3A', '2A', '1A', 'CC'),
    1 + MOD(n * 11, 72),
    300 + MOD(n * 37, 2700),
    ELT(MOD(FLOOR(n / 3), 3) + 1, 'Confirmed', 'Waiting', 'Cancelled')
FROM seq;

/* ---------------------------------------------------------------------------
   STEP 3: VERIFY POPULATED DATA
   PURPOSE: Confirm 6,000 rows were inserted and preview the first 5 records.
   --------------------------------------------------------------------------- */
SELECT COUNT(*) AS total_records
FROM Railway_Booking;

SELECT *
FROM Railway_Booking
LIMIT 5;

/* ---------------------------------------------------------------------------
   STAGE 1.1: EXPLAIN - QUERY 1 (BEFORE INDEXING)
   PURPOSE: Inspect execution plan for single-column filter on train_no.
   KEY IDEA: Without secondary indexes, MySQL performs a full table scan
             (type = ALL) examining all 6,000 rows.
   --------------------------------------------------------------------------- */
EXPLAIN
SELECT *
FROM Railway_Booking
WHERE train_no = 12038;

/* ---------------------------------------------------------------------------
   STAGE 1.2: EXPLAIN ANALYZE - QUERY 1 (BEFORE INDEXING)
   PURPOSE: Measure actual execution time and rows scanned for Query 1.
   --------------------------------------------------------------------------- */
EXPLAIN ANALYZE
SELECT *
FROM Railway_Booking
WHERE train_no = 12038;

/* ---------------------------------------------------------------------------
   STAGE 1.3: EXPLAIN - QUERY 2 (BEFORE INDEXING)
   PURPOSE: Inspect execution plan for combined filter on train_no and date.
   --------------------------------------------------------------------------- */
EXPLAIN
SELECT *
FROM Railway_Booking
WHERE train_no = 12038
  AND journey_date = '2026-05-20';

/* ---------------------------------------------------------------------------
   STAGE 1.4: EXPLAIN ANALYZE - QUERY 2 (BEFORE INDEXING)
   PURPOSE: Measure actual execution time and rows scanned for Query 2.
   --------------------------------------------------------------------------- */
EXPLAIN ANALYZE
SELECT *
FROM Railway_Booking
WHERE train_no = 12038
  AND journey_date = '2026-05-20';

/* ---------------------------------------------------------------------------
   STAGE 2.1: CREATE SINGLE-COLUMN INDEX ON TRAIN_NO
   PURPOSE: Create B-tree index idx_train_no and refresh table statistics.
   --------------------------------------------------------------------------- */
CREATE INDEX idx_train_no
ON Railway_Booking(train_no);

ANALYZE TABLE Railway_Booking;
SHOW INDEX FROM Railway_Booking;

/* ---------------------------------------------------------------------------
   STAGE 2.2: EXPLAIN - QUERY 1 (AFTER SINGLE-COLUMN INDEX)
   PURPOSE: Verify that MySQL uses idx_train_no (type = ref) instead of ALL.
   --------------------------------------------------------------------------- */
EXPLAIN
SELECT *
FROM Railway_Booking
WHERE train_no = 12038;

/* ---------------------------------------------------------------------------
   STAGE 2.3: EXPLAIN ANALYZE - QUERY 1 (AFTER SINGLE-COLUMN INDEX)
   PURPOSE: Measure improved actual runtime using idx_train_no.
   --------------------------------------------------------------------------- */
EXPLAIN ANALYZE
SELECT *
FROM Railway_Booking
WHERE train_no = 12038;

/* ---------------------------------------------------------------------------
   STAGE 2.4: EXPLAIN - QUERY 2 (AFTER SINGLE-COLUMN INDEX)
   PURPOSE: Observe optimizer using idx_train_no to narrow rows before
            filtering journey_date.
   --------------------------------------------------------------------------- */
EXPLAIN
SELECT *
FROM Railway_Booking
WHERE train_no = 12038
  AND journey_date = '2026-05-20';

/* ---------------------------------------------------------------------------
   STAGE 2.5: EXPLAIN ANALYZE - QUERY 2 (AFTER SINGLE-COLUMN INDEX)
   PURPOSE: Measure runtime when only the first predicate column is indexed.
   --------------------------------------------------------------------------- */
EXPLAIN ANALYZE
SELECT *
FROM Railway_Booking
WHERE train_no = 12038
  AND journey_date = '2026-05-20';

/* ---------------------------------------------------------------------------
   STAGE 3.1: CREATE COMPOSITE INDEX ON (TRAIN_NO, JOURNEY_DATE)
   PURPOSE: Create multi-column index idx_train_date covering both predicates.
   --------------------------------------------------------------------------- */
CREATE INDEX idx_train_date
ON Railway_Booking(train_no, journey_date);

ANALYZE TABLE Railway_Booking;
SHOW INDEX FROM Railway_Booking;

/* ---------------------------------------------------------------------------
   STAGE 3.2: EXPLAIN - QUERY 2 (AFTER COMPOSITE INDEX)
   PURPOSE: Verify composite index lookup using idx_train_date for both columns.
   --------------------------------------------------------------------------- */
EXPLAIN
SELECT *
FROM Railway_Booking
WHERE train_no = 12038
  AND journey_date = '2026-05-20';

/* ---------------------------------------------------------------------------
   STAGE 3.3: EXPLAIN ANALYZE - QUERY 2 (AFTER COMPOSITE INDEX)
   PURPOSE: Measure runtime with composite index lookup.
   --------------------------------------------------------------------------- */
EXPLAIN ANALYZE
SELECT *
FROM Railway_Booking
WHERE train_no = 12038
  AND journey_date = '2026-05-20';

/* ---------------------------------------------------------------------------
   STAGE 3.4: EXPLAIN - QUERY 3 (LEFTMOST-PREFIX RULE TEST)
   PURPOSE: Filter solely on journey_date (the second column of idx_train_date).
   KEY IDEA: A composite index on (train_no, journey_date) cannot be used
             efficiently when the leading column (train_no) is omitted.
   --------------------------------------------------------------------------- */
EXPLAIN
SELECT *
FROM Railway_Booking
WHERE journey_date = '2026-05-20';

/* ---------------------------------------------------------------------------
   STAGE 3.5: EXPLAIN ANALYZE - QUERY 3 (LEFTMOST-PREFIX RULE TEST)
   PURPOSE: Measure table scan fallback when leftmost prefix is not satisfied.
   --------------------------------------------------------------------------- */
EXPLAIN ANALYZE
SELECT *
FROM Railway_Booking
WHERE journey_date = '2026-05-20';

/* ============================== END ========================================
   SUMMARY
   - Without secondary indexes, queries perform a full table scan (type = ALL).
   - Single-column index idx_train_no enables index lookup (type = ref) on train_no.
   - Composite index idx_train_date optimizes combined (train_no, journey_date) lookups.
   - Composite indexes follow the leftmost-prefix rule; querying only journey_date
     cannot use idx_train_date efficiently.
   ============================================================================ */
