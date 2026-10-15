/* ============================================================================
   DBMS LAB - EXPERIMENT 5
   TITLE: VIEWS, VIEW UPDATABILITY AND RECURSIVE COMMON TABLE EXPRESSIONS
   DBMS: MySQL 8.0+

   AIM
   ---
   To create views for department salary summaries and employee hierarchy,
   test whether a simple view can be updated, and display reporting chains using
   a recursive CTE.

   HOW TO RUN
   ----------
   1. Run this complete file in MySQL Workbench or another MySQL 8.0+ editor.
   2. This experiment uses its own database, ViewCTEDB, so it does not interfere
      with the CompanyDB database used in Experiments 3, 4 and 6.
   3. Re-running this script will not duplicate the sample rows. The salary
      update in Section 6 adds 5000 each time it is run; comment it out if you
      only want to inspect the current salary.

   TABLES
   ------
   department(department_id, department_name)
   employee(employee_id, employee_name, department_id, manager_id, salary)
   ============================================================================ */

/* SECTION 1: SELECT THE DATABASE ------------------------------------------- */
CREATE DATABASE IF NOT EXISTS ViewCTEDB;
USE ViewCTEDB;

/* SECTION 2: CREATE THE DEPARTMENT TABLE ----------------------------------- */
CREATE TABLE IF NOT EXISTS department (
    department_id INT PRIMARY KEY,
    department_name VARCHAR(50) NOT NULL
);

/* SECTION 3: CREATE THE EMPLOYEE TABLE -------------------------------------
   manager_id refers to another employee's employee_id. A NULL manager_id means
   the employee is at the top of the reporting hierarchy. */
CREATE TABLE IF NOT EXISTS employee (
    employee_id INT PRIMARY KEY,
    employee_name VARCHAR(100) NOT NULL,
    department_id INT,
    manager_id INT NULL,
    salary DECIMAL(10,2),
    CONSTRAINT fk_employee_department
        FOREIGN KEY (department_id) REFERENCES department(department_id),
    CONSTRAINT fk_employee_manager
        FOREIGN KEY (manager_id) REFERENCES employee(employee_id)
);

/* SECTION 4: INSERT SAMPLE DEPARTMENTS -------------------------------------
   Insert departments only when the table is empty. */
INSERT INTO department (department_id, department_name)
SELECT src.department_id, src.department_name
FROM (
    SELECT 1 AS department_id, 'IT' AS department_name
    UNION ALL SELECT 2, 'HR'
    UNION ALL SELECT 3, 'Finance'
) AS src
WHERE NOT EXISTS (SELECT 1 FROM department);

/* SECTION 5: INSERT SAMPLE EMPLOYEES ---------------------------------------
   Add managers before their direct reports to satisfy the manager foreign key. */
INSERT INTO employee (employee_id, employee_name, department_id, manager_id, salary)
SELECT 101, 'Amit', 1, NULL, 90000
WHERE NOT EXISTS (SELECT 1 FROM employee WHERE employee_id = 101);

INSERT INTO employee (employee_id, employee_name, department_id, manager_id, salary)
SELECT 104, 'Priya', 2, NULL, 80000
WHERE NOT EXISTS (SELECT 1 FROM employee WHERE employee_id = 104);

INSERT INTO employee (employee_id, employee_name, department_id, manager_id, salary)
SELECT 106, 'Riya', 3, NULL, 85000
WHERE NOT EXISTS (SELECT 1 FROM employee WHERE employee_id = 106);

INSERT INTO employee (employee_id, employee_name, department_id, manager_id, salary)
SELECT 102, 'Neha', 1, 101, 65000
WHERE NOT EXISTS (SELECT 1 FROM employee WHERE employee_id = 102);

INSERT INTO employee (employee_id, employee_name, department_id, manager_id, salary)
SELECT 103, 'Rahul', 1, 101, 60000
WHERE NOT EXISTS (SELECT 1 FROM employee WHERE employee_id = 103);

INSERT INTO employee (employee_id, employee_name, department_id, manager_id, salary)
SELECT 105, 'Karan', 2, 104, 55000
WHERE NOT EXISTS (SELECT 1 FROM employee WHERE employee_id = 105);

INSERT INTO employee (employee_id, employee_name, department_id, manager_id, salary)
SELECT 107, 'Arjun', 3, 106, 50000
WHERE NOT EXISTS (SELECT 1 FROM employee WHERE employee_id = 107);

/* OPTIONAL CHECK: Inspect the sample data before creating the views. */
SELECT * FROM department ORDER BY department_id;
SELECT * FROM employee ORDER BY employee_id;

/* SECTION 6: VIEW 1 - DEPARTMENT SALARY SUMMARY ----------------------------
   A VIEW is a saved SELECT query that can be queried like a virtual table.
   This view calculates employee count, total salary, and average salary for
   each department. LEFT JOIN also keeps departments with no employees. */
CREATE OR REPLACE VIEW department_salary_summary AS
SELECT
    d.department_id,
    d.department_name,
    COUNT(e.employee_id) AS employee_count,
    SUM(e.salary) AS total_salary,
    AVG(e.salary) AS average_salary
FROM department AS d
LEFT JOIN employee AS e
    ON d.department_id = e.department_id
GROUP BY d.department_id, d.department_name;

/* Display the department summary. */
SELECT *
FROM department_salary_summary
ORDER BY department_id;

/* SECTION 7: VIEW 2 - EMPLOYEE HIERARCHY ----------------------------------
   This view joins employee to itself: e is the employee and m is the manager.
   LEFT JOIN keeps top-level employees whose manager_id is NULL. */
CREATE OR REPLACE VIEW employee_hierarchy AS
SELECT
    e.employee_id,
    e.employee_name,
    e.department_id,
    e.manager_id,
    m.employee_name AS manager_name,
    e.salary
FROM employee AS e
LEFT JOIN employee AS m
    ON e.manager_id = m.employee_id;

/* Display employee names together with their managers. */
SELECT *
FROM employee_hierarchy
ORDER BY employee_id;

/* SECTION 8: TEST VIEW UPDATABILITY ---------------------------------------
   This simple view uses one base table and no grouping or joins, so it is
   updatable in MySQL. Updating the view updates the underlying employee row. */
CREATE OR REPLACE VIEW employee_basic AS
SELECT employee_id, employee_name, salary
FROM employee;

/* Test update: add 5000 to Neha's salary (employee_id 102).
   IMPORTANT: Re-running this statement adds another 5000 each time. */
UPDATE employee_basic
SET salary = salary + 5000
WHERE employee_id = 102;

/* Verify the salary after the update. */
SELECT *
FROM employee_basic
WHERE employee_id = 102;

/* SECTION 9: RECURSIVE CTE - EMPLOYEE REPORTING CHAIN ----------------------
   A CTE (Common Table Expression) is a named temporary result for one query.
   A recursive CTE has two parts:
     1. Anchor member: starts with employees who have no manager.
     2. Recursive member: finds employees reporting to the previous level.
   reporting_path shows the full chain, for example: Amit -> Neha. */
WITH RECURSIVE reporting_chain AS (
    /* Anchor member: top-level employees. */
    SELECT
        employee_id,
        employee_name,
        manager_id,
        0 AS level,
        CAST(employee_name AS CHAR(1000)) AS reporting_path
    FROM employee
    WHERE manager_id IS NULL

    UNION ALL

    /* Recursive member: find employees who report to the current employee. */
    SELECT
        e.employee_id,
        e.employee_name,
        e.manager_id,
        rc.level + 1,
        CONCAT(rc.reporting_path, ' -> ', e.employee_name)
    FROM employee AS e
    INNER JOIN reporting_chain AS rc
        ON e.manager_id = rc.employee_id
)
SELECT
    employee_id,
    employee_name,
    manager_id,
    level,
    reporting_path
FROM reporting_chain
ORDER BY reporting_path;

/* ============================== END ========================================
   WHAT THIS EXPERIMENT DEMONSTRATES
   - Views simplify repeated queries and present selected data.
   - A simple single-table view can be updatable.
   - A recursive CTE can walk through a manager/employee hierarchy.
   ============================================================================ */
