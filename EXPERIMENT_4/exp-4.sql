/* ============================================================================
   DBMS LAB - EXPERIMENT 4
   TITLE: JOINS, SUBQUERIES, SET OPERATIONS AND QUERY EXECUTION PLANS
   DBMS: MySQL 8.0+

   AIM
   ---
   To practise INNER JOIN, LEFT JOIN, SELF JOIN, three-table JOIN, correlated
   subqueries, EXISTS, simulated INTERSECT/EXCEPT, and EXPLAIN.

   BEFORE YOU RUN
   --------------
   1. Run Experiment 3 first. It creates and populates CompanyDB.
   2. Execute this file from top to bottom in MySQL Workbench or a compatible tool.
   3. Each numbered section is independent and can also be executed separately.

   TABLES USED
   -----------
   Employee(emp_id, emp_name, salary, hire_date, dept_id, project_id)
   Department(dept_id, dept_name)
   Project(project_id, project_name, budget, dept_id)
   ============================================================================ */

USE CompanyDB;

/* ---------------------------------------------------------------------------
   QUERY 1: INNER JOIN
   PURPOSE: Show employees that have a matching department record.
   KEY IDEA: INNER JOIN returns rows that match the ON condition in both tables.
   --------------------------------------------------------------------------- */
SELECT
    e.emp_id,
    e.emp_name,
    e.salary,
    d.dept_name
FROM Employee AS e
INNER JOIN Department AS d
    ON e.dept_id = d.dept_id
ORDER BY e.emp_id;

/* ---------------------------------------------------------------------------
   QUERY 2: LEFT JOIN
   PURPOSE: List every department and its employees, if any.
   KEY IDEA: All rows from Department are kept. If no employee matches, the
             Employee columns appear as NULL.
   --------------------------------------------------------------------------- */
SELECT
    d.dept_id,
    d.dept_name,
    e.emp_name,
    e.salary
FROM Department AS d
LEFT JOIN Employee AS e
    ON d.dept_id = e.dept_id
ORDER BY d.dept_id, e.emp_id;

/* ---------------------------------------------------------------------------
   QUERY 3: SELF JOIN
   PURPOSE: Compare employees who belong to the same department.
   KEY IDEA: Employee is joined to itself using two aliases (e1 and e2).
             e1.emp_id < e2.emp_id avoids pairing an employee with themselves
             and prevents showing the same pair in reverse order.
   LIMIT: Show only the first 10 pairs to keep the output manageable.
   --------------------------------------------------------------------------- */
SELECT
    e1.emp_name AS employee_1,
    e2.emp_name AS employee_2,
    e1.dept_id,
    e1.salary AS salary_1,
    e2.salary AS salary_2
FROM Employee AS e1
INNER JOIN Employee AS e2
    ON e1.dept_id = e2.dept_id
   AND e1.emp_id < e2.emp_id
ORDER BY e1.dept_id, e1.emp_id, e2.emp_id
LIMIT 10;

/* ---------------------------------------------------------------------------
   QUERY 4: THREE-TABLE JOIN
   PURPOSE: Display each employee with department and project details.
   KEY IDEA: Employee connects to Department through dept_id and to Project
             through project_id.
   --------------------------------------------------------------------------- */
SELECT
    e.emp_id,
    e.emp_name,
    d.dept_name,
    p.project_name,
    e.salary
FROM Employee AS e
INNER JOIN Department AS d
    ON e.dept_id = d.dept_id
INNER JOIN Project AS p
    ON e.project_id = p.project_id
ORDER BY d.dept_name, e.emp_name;

/* ---------------------------------------------------------------------------
   QUERY 5: CORRELATED SUBQUERY
   PURPOSE: Find employees earning more than their own department's average.
   KEY IDEA: The inner query refers to e.dept_id from the outer query, so its
             average is calculated for the current employee's department.
   --------------------------------------------------------------------------- */
SELECT
    e.emp_id,
    e.emp_name,
    e.salary,
    e.dept_id
FROM Employee AS e
WHERE e.salary > (
    SELECT AVG(e2.salary)
    FROM Employee AS e2
    WHERE e2.dept_id = e.dept_id
)
ORDER BY e.dept_id, e.salary DESC;

/* ---------------------------------------------------------------------------
   QUERY 6: EXISTS
   PURPOSE: Find departments with at least one employee earning over 80000.
   KEY IDEA: EXISTS is TRUE when its subquery returns at least one row.
   --------------------------------------------------------------------------- */
SELECT
    d.dept_id,
    d.dept_name
FROM Department AS d
WHERE EXISTS (
    SELECT 1
    FROM Employee AS e
    WHERE e.dept_id = d.dept_id
      AND e.salary > 80000
)
ORDER BY d.dept_id;

/* ---------------------------------------------------------------------------
   QUERY 7: SIMULATED INTERSECT
   PURPOSE: Find employees who satisfy BOTH conditions:
             (a) belong to IT (dept_id = 1), and (b) earn over 70000.
   KEY IDEA: MySQL versions without INTERSECT can express this with AND/IN.
   --------------------------------------------------------------------------- */
SELECT emp_id, emp_name, salary
FROM Employee
WHERE dept_id = 1
  AND salary > 70000
ORDER BY emp_id;

/* ---------------------------------------------------------------------------
   QUERY 8: SIMULATED EXCEPT
   PURPOSE: Find employees earning over 70000, excluding the IT department.
   KEY IDEA: The WHERE clause keeps the required group and excludes dept_id 1.
   --------------------------------------------------------------------------- */
SELECT emp_id, emp_name, salary
FROM Employee
WHERE salary > 70000
  AND dept_id <> 1
ORDER BY emp_id;

/* ---------------------------------------------------------------------------
   QUERY 9A: EXPLAIN FOR INNER JOIN
   PURPOSE: Display MySQL's planned approach for this JOIN query.
   NOTE: EXPLAIN shows the query plan; it does not return employee results.
   --------------------------------------------------------------------------- */
EXPLAIN
SELECT e.emp_name, d.dept_name
FROM Employee AS e
INNER JOIN Department AS d
    ON e.dept_id = d.dept_id
WHERE e.salary > 70000;

/* ---------------------------------------------------------------------------
   QUERY 9B: EXPLAIN FOR CORRELATED SUBQUERY
   PURPOSE: Inspect the execution plan for the department-average query.
   --------------------------------------------------------------------------- */
EXPLAIN
SELECT e.emp_name, e.salary
FROM Employee AS e
WHERE e.salary > (
    SELECT AVG(e2.salary)
    FROM Employee AS e2
    WHERE e2.dept_id = e.dept_id
);

/* ---------------------------------------------------------------------------
   QUERY 9C: EXPLAIN FOR EXISTS
   PURPOSE: Inspect the plan for an existence-based department query.
   --------------------------------------------------------------------------- */
EXPLAIN
SELECT d.dept_name
FROM Department AS d
WHERE EXISTS (
    SELECT 1
    FROM Employee AS e
    WHERE e.dept_id = d.dept_id
      AND e.salary > 80000
);

/* ============================== END ========================================
   SUMMARY
   - INNER JOIN returns matching rows.
   - LEFT JOIN preserves every row from the left table.
   - SELF JOIN compares rows within the same table.
   - Correlated subqueries use values from the outer query.
   - EXISTS checks whether a matching row exists.
   - EXPLAIN displays the execution plan selected by MySQL.
   ============================================================================ */
