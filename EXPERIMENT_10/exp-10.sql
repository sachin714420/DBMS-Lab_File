/* ============================================================================
   DBMS LAB - EXPERIMENT 10
   TITLE: SQL QUERY OPTIMIZATION AND EXECUTION PLAN ANALYSIS
   DBMS: MySQL 8.0+

   AIM
   ---
   To generate a dataset containing at least 10,000 rows, identify five slow SQL
   queries, analyze their execution plans using EXPLAIN, optimize them using
   indexing and query rewriting, and compare execution plans before and after.

   BEFORE YOU RUN
   --------------
   1. Execute this file from top to bottom in MySQL Workbench or a compatible tool.
   2. This script automatically creates QueryLabDB and populates 10,000 rows.
   3. Each numbered query runs the slow version first, creates appropriate
      indexes, and then executes the optimized rewrite.

   TABLES USED
   -----------
   EmployeeData(emp_id, emp_name, department, salary, city, hire_date,
                performance_score)
   ============================================================================ */

CREATE DATABASE IF NOT EXISTS QueryLabDB;
USE QueryLabDB;

/* ---------------------------------------------------------------------------
   STEP 1: CREATE THE EMPLOYEEDATA TABLE
   PURPOSE: Define the schema for 10,000 employee records.
   --------------------------------------------------------------------------- */
DROP TABLE IF EXISTS EmployeeData;
CREATE TABLE EmployeeData (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(60) NOT NULL,
    department VARCHAR(30) NOT NULL,
    salary INT NOT NULL,
    city VARCHAR(40) NOT NULL,
    hire_date DATE NOT NULL,
    performance_score DECIMAL(4,2) NOT NULL
);

/* ---------------------------------------------------------------------------
   STEP 2: GENERATE 10,000 ROWS USING RECURSIVE CTE
   PURPOSE: Populate EmployeeData with 10,000 synthetic employee records.
   --------------------------------------------------------------------------- */
SET SESSION cte_max_recursion_depth = 10001;

INSERT INTO EmployeeData (
    emp_id,
    emp_name,
    department,
    salary,
    city,
    hire_date,
    performance_score
)
WITH RECURSIVE numbers AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM numbers WHERE n < 10000
)
SELECT
    n,
    CONCAT('Employee_', n),
    ELT((n MOD 5) + 1, 'IT', 'HR', 'Finance', 'Sales', 'Operations'),
    30000 + ((n * 137) MOD 90001),
    ELT((n MOD 6) + 1, 'Lucknow', 'Delhi', 'Mumbai', 'Pune', 'Jaipur', 'Chennai'),
    DATE_ADD('2015-01-01', INTERVAL (n MOD 3500) DAY),
    1.00 + ((n MOD 50) / 10.0)
FROM numbers;

SELECT COUNT(*) AS total_rows
FROM EmployeeData;

/* ---------------------------------------------------------------------------
   QUERY 1A: FUNCTION APPLIED TO COLUMN (UNOPTIMIZED)
   PURPOSE: Inspect execution plan when YEAR(hire_date) wraps the column.
   KEY IDEA: Applying a function to an indexed column makes the predicate
             non-sargable, forcing a full table scan (type = ALL).
   --------------------------------------------------------------------------- */
EXPLAIN
SELECT emp_id, emp_name, hire_date
FROM EmployeeData
WHERE YEAR(hire_date) = 2022;

SELECT emp_id, emp_name, hire_date
FROM EmployeeData
WHERE YEAR(hire_date) = 2022;

/* ---------------------------------------------------------------------------
   QUERY 1B: SARGABLE DATE RANGE + INDEX (OPTIMIZED)
   PURPOSE: Index hire_date and rewrite YEAR(hire_date) as an explicit range.
   KEY IDEA: Range predicates (>= and <) allow MySQL to use idx_hire_date
             via an index range scan (type = range).
   --------------------------------------------------------------------------- */
CREATE INDEX idx_hire_date
ON EmployeeData(hire_date);

EXPLAIN
SELECT emp_id, emp_name, hire_date
FROM EmployeeData
WHERE hire_date >= '2022-01-01'
  AND hire_date < '2023-01-01';

SELECT emp_id, emp_name, hire_date
FROM EmployeeData
WHERE hire_date >= '2022-01-01'
  AND hire_date < '2023-01-01';

/* ---------------------------------------------------------------------------
   QUERY 2A: LEADING WILDCARD IN LIKE (UNOPTIMIZED)
   PURPOSE: Inspect execution plan for pattern '%999%' with a leading wildcard.
   KEY IDEA: Leading wildcards prevent standard B-tree prefix lookups, causing
             a full scan of all 10,000 rows.
   --------------------------------------------------------------------------- */
EXPLAIN
SELECT emp_id, emp_name
FROM EmployeeData
WHERE emp_name LIKE '%999%';

SELECT emp_id, emp_name
FROM EmployeeData
WHERE emp_name LIKE '%999%';

/* ---------------------------------------------------------------------------
   QUERY 2B: PREFIX WILDCARD + INDEX (OPTIMIZED)
   PURPOSE: Index emp_name and rewrite as prefix match 'Employee_999%'.
   KEY IDEA: A trailing wildcard allows B-tree index range scanning.
   NOTE: Semantics change from "contains 999" to "starts with Employee_999".
   --------------------------------------------------------------------------- */
CREATE INDEX idx_emp_name
ON EmployeeData(emp_name);

EXPLAIN
SELECT emp_id, emp_name
FROM EmployeeData
WHERE emp_name LIKE 'Employee_999%';

SELECT emp_id, emp_name
FROM EmployeeData
WHERE emp_name LIKE 'Employee_999%';

/* ---------------------------------------------------------------------------
   QUERY 3A: FILTER ON UNINDEXED COLUMN (UNOPTIMIZED)
   PURPOSE: Inspect execution plan when filtering by department without an index.
   --------------------------------------------------------------------------- */
EXPLAIN
SELECT emp_id, emp_name, salary
FROM EmployeeData
WHERE department = 'Finance';

SELECT emp_id, emp_name, salary
FROM EmployeeData
WHERE department = 'Finance';

/* ---------------------------------------------------------------------------
   QUERY 3B: SINGLE-COLUMN INDEX ON DEPARTMENT (OPTIMIZED)
   PURPOSE: Add idx_department to switch from full scan to index lookup (ref).
   --------------------------------------------------------------------------- */
CREATE INDEX idx_department
ON EmployeeData(department);

EXPLAIN
SELECT emp_id, emp_name, salary
FROM EmployeeData
WHERE department = 'Finance';

SELECT emp_id, emp_name, salary
FROM EmployeeData
WHERE department = 'Finance';

/* ---------------------------------------------------------------------------
   QUERY 4A: CORRELATED SUBQUERY (UNOPTIMIZED)
   PURPOSE: Find employees earning above their department's average salary.
   KEY IDEA: A correlated subquery logically evaluates the inner AVG() per
             outer row, leading to high execution overhead.
   --------------------------------------------------------------------------- */
EXPLAIN
SELECT e.emp_id, e.emp_name, e.department, e.salary
FROM EmployeeData AS e
WHERE e.salary > (
    SELECT AVG(e2.salary)
    FROM EmployeeData AS e2
    WHERE e2.department = e.department
);

SELECT e.emp_id, e.emp_name, e.department, e.salary
FROM EmployeeData AS e
WHERE e.salary > (
    SELECT AVG(e2.salary)
    FROM EmployeeData AS e2
    WHERE e2.department = e.department
);

/* ---------------------------------------------------------------------------
   QUERY 4B: DERIVED TABLE JOIN + COVERING INDEX (OPTIMIZED)
   PURPOSE: Pre-compute department averages once in a derived table and join.
   KEY IDEA: Composite index idx_department_salary covers GROUP BY department
             and AVG(salary) via an index scan without reading table rows.
   --------------------------------------------------------------------------- */
CREATE INDEX idx_department_salary
ON EmployeeData(department, salary);

EXPLAIN
SELECT e.emp_id, e.emp_name, e.department, e.salary
FROM EmployeeData AS e
INNER JOIN (
    SELECT department, AVG(salary) AS avg_salary
    FROM EmployeeData
    GROUP BY department
) AS d
    ON d.department = e.department
WHERE e.salary > d.avg_salary;

SELECT e.emp_id, e.emp_name, e.department, e.salary
FROM EmployeeData AS e
INNER JOIN (
    SELECT department, AVG(salary) AS avg_salary
    FROM EmployeeData
    GROUP BY department
) AS d
    ON d.department = e.department
WHERE e.salary > d.avg_salary;

/* ---------------------------------------------------------------------------
   QUERY 5A: OR CONDITION ACROSS COLUMNS (UNOPTIMIZED)
   PURPOSE: Inspect execution plan for filtering on department OR city.
   KEY IDEA: Filtering across two unindexed/different columns with OR often
             forces a full table scan.
   --------------------------------------------------------------------------- */
EXPLAIN
SELECT emp_id, emp_name, department, city
FROM EmployeeData
WHERE department = 'IT'
   OR city = 'Lucknow';

SELECT emp_id, emp_name, department, city
FROM EmployeeData
WHERE department = 'IT'
   OR city = 'Lucknow';

/* ---------------------------------------------------------------------------
   QUERY 5B: REWRITE OR AS UNION + INDEX (OPTIMIZED)
   PURPOSE: Add idx_city and split the OR predicates into two SELECTs joined
            with UNION.
   KEY IDEA: UNION allows each branch to use its respective index while
             eliminating duplicate rows just like OR.
   --------------------------------------------------------------------------- */
CREATE INDEX idx_city
ON EmployeeData(city);

EXPLAIN
SELECT emp_id, emp_name, department, city
FROM EmployeeData
WHERE department = 'IT'
UNION
SELECT emp_id, emp_name, department, city
FROM EmployeeData
WHERE city = 'Lucknow';

SELECT emp_id, emp_name, department, city
FROM EmployeeData
WHERE department = 'IT'
UNION
SELECT emp_id, emp_name, department, city
FROM EmployeeData
WHERE city = 'Lucknow';

/* ============================== END ========================================
   SUMMARY
   - Sargable range predicates replace column functions to enable index usage.
   - Prefix LIKE patterns allow B-tree range lookups unlike leading wildcards.
   - Indexing filter columns eliminates full table scans.
   - Derived table joins with covering indexes outperform correlated subqueries.
   - Rewriting OR across columns as UNION enables separate index paths.
   ============================================================================ */
