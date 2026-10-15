/*
===============================================================================
                    DBMS LAB - EXPERIMENT 3
===============================================================================
TITLE : Employee-Department-Project Database and Basic SQL Queries

AIM:
To create an Employee-Department-Project relational database, insert 30
employees across 5 departments and 8 projects, and demonstrate Selection,
Projection, Aggregate Functions, GROUP BY, HAVING, CASE expressions, ORDER BY,
and JOIN operations.

DATABASE : MySQL 8.0 or later recommended

IMPORTANT:
1. Run this script in order, from top to bottom.
2. This script creates the database tables and inserts sample records.
3. If you run the INSERT statements again, duplicate primary-key errors may
   occur. Use a fresh database or remove existing sample records first.
===============================================================================
*/

-- ============================================================================
-- SECTION 1: CREATE AND SELECT THE DATABASE
-- ============================================================================

CREATE DATABASE IF NOT EXISTS CompanyDB;
USE CompanyDB;

-- ============================================================================
-- SECTION 2: CREATE TABLES
-- Create Department and Project before Employee because Employee references
-- both tables through foreign keys.
-- ============================================================================

-- Table 1: Stores department information.
CREATE TABLE IF NOT EXISTS Department (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50) NOT NULL
);

-- Table 2: Stores project information and its associated department.
CREATE TABLE IF NOT EXISTS Project (
    project_id INT PRIMARY KEY,
    project_name VARCHAR(100) NOT NULL,
    budget DECIMAL(12,2),
    dept_id INT,
    FOREIGN KEY (dept_id) REFERENCES Department(dept_id)
);

-- Table 3: Stores employee details, department and assigned project.
CREATE TABLE IF NOT EXISTS Employee (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(50) NOT NULL,
    salary DECIMAL(10,2),
    hire_date DATE,
    dept_id INT,
    project_id INT,
    FOREIGN KEY (dept_id) REFERENCES Department(dept_id),
    FOREIGN KEY (project_id) REFERENCES Project(project_id)
);

-- ============================================================================
-- SECTION 3: INSERT SAMPLE DATA
-- ============================================================================

-- 3.1 Insert five departments.
INSERT INTO Department (dept_id, dept_name) VALUES
(1, 'IT'),
(2, 'HR'),
(3, 'Finance'),
(4, 'Marketing'),
(5, 'Operations');

-- 3.2 Insert eight projects.
INSERT INTO Project (project_id, project_name, budget, dept_id) VALUES
(101, 'Cloud Migration', 150000, 1),
(102, 'AI Analytics', 200000, 1),
(103, 'Recruitment Portal', 80000, 2),
(104, 'Financial Dashboard', 120000, 3),
(105, 'Digital Campaign', 90000, 4),
(106, 'Supply Chain System', 180000, 5),
(107, 'Mobile Application', 140000, 1),
(108, 'Employee Wellness', 60000, 2);

-- 3.3 Insert thirty employees.
INSERT INTO Employee (emp_id, emp_name, salary, hire_date, dept_id, project_id) VALUES
(1, 'Ujjawal', 650000, '2022-01-10', 1, 101),
(2, 'Krish', 72000, '2021-03-15', 1, 102),
(3, 'Umesh', 58000, '2023-06-20', 1, 107),
(4, 'Jonny', 81000, '2020-08-12', 1, 101),
(5, 'Karina', 69000, '2022-11-05', 1, 102),
(6, 'Reyansh', 62000, '2024-02-18', 1, 107),
(7, 'Ananya', 52000, '2022-04-11', 2, 103),
(8, 'Diya', 48000, '2023-01-22', 2, 108),
(9, 'Myra', 61000, '2021-07-19', 2, 103),
(10, 'Sara', 55000, '2022-09-30', 2, 108),
(11, 'Ishita', 47000, '2024-03-14', 2, 103),
(12, 'Meera', 59000, '2020-12-01', 2, 108),
(13, 'Rohan', 75000, '2021-02-17', 3, 104),
(14, 'Karan', 68000, '2022-05-09', 3, 104),
(15, 'Nikhil', 83000, '2019-10-21', 3, 104),
(16, 'Yash', 62000, '2023-08-13', 3, 104),
(17, 'Manav', 71000, '2021-11-28', 3, 104),
(18, 'Dev', 56000, '2024-01-09', 3, 104),
(19, 'Aanya', 54000, '2022-02-25', 4, 105),
(20, 'Kiara', 63000, '2021-06-16', 4, 105),
(21, 'Tanya', 57000, '2023-04-10', 4, 105),
(22, 'Riya', 66000, '2020-09-07', 4, 105),
(23, 'Avni', 51000, '2024-02-05', 4, 105),
(24, 'Navya', 70000, '2022-12-19', 4, 105),
(25, 'Samar', 60000, '2021-01-12', 5, 106),
(26, 'Dhruv', 73000, '2020-04-23', 5, 106),
(27, 'Atharv', 67000, '2022-07-18', 5, 106),
(28, 'Parth', 59000, '2023-05-29', 5, 106),
(29, 'Rudra', 76000, '2019-08-31', 5, 106),
(30, 'Veer', 64000, '2024-01-20', 5, 106);

-- ============================================================================
-- SECTION 4: SELECTION
-- Concept: WHERE filters rows based on a condition.
-- Task: Display employees whose salary is greater than 70,000.
-- ============================================================================

SELECT *
FROM Employee
WHERE salary > 70000;

-- ============================================================================
-- SECTION 5: PROJECTION
-- Concept: Projection means selecting specific columns from a table.
-- Task: Display only employee names and salaries.
-- ============================================================================

SELECT emp_name, salary
FROM Employee;

-- ============================================================================
-- SECTION 6: AGGREGATE FUNCTIONS
-- Concept: COUNT, AVG, MAX, MIN and SUM calculate summary values.
-- Task: Find employee count, average, highest, lowest and total salary.
-- ============================================================================

SELECT
    COUNT(*) AS total_employees,
    AVG(salary) AS average_salary,
    MAX(salary) AS highest_salary,
    MIN(salary) AS lowest_salary,
    SUM(salary) AS total_salary
FROM Employee;

-- ============================================================================
-- SECTION 7: GROUP BY
-- Concept: GROUP BY groups rows that share the same department.
-- Task: Show employee count and average salary for every department.
-- ============================================================================

SELECT
    d.dept_name,
    COUNT(e.emp_id) AS employee_count,
    AVG(e.salary) AS average_salary
FROM Department AS d
JOIN Employee AS e
    ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name;

-- ============================================================================
-- SECTION 8: HAVING
-- Concept: HAVING filters groups after GROUP BY has been applied.
-- Task: Display departments whose average salary is greater than 65,000.
-- ============================================================================

SELECT
    d.dept_name,
    AVG(e.salary) AS average_salary
FROM Department AS d
JOIN Employee AS e
    ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
HAVING AVG(e.salary) > 65000;

-- ============================================================================
-- SECTION 9: CASE EXPRESSION
-- Concept: CASE returns a value based on the first matching condition.
-- Task: Classify each employee as High, Medium or Low Salary.
-- ============================================================================

SELECT
    emp_name,
    salary,
    CASE
        WHEN salary >= 75000 THEN 'High Salary'
        WHEN salary >= 60000 THEN 'Medium Salary'
        ELSE 'Low Salary'
    END AS salary_category
FROM Employee;

-- ============================================================================
-- SECTION 10: ORDER BY
-- Concept: ORDER BY sorts the result set. DESC means highest to lowest.
-- Task: Display employees in descending order of salary.
-- ============================================================================

SELECT emp_name, salary
FROM Employee
ORDER BY salary DESC;

-- ============================================================================
-- SECTION 11: THREE-TABLE JOIN
-- Concept: JOIN combines related rows from Employee, Department and Project.
-- Task: Display employee name, department, project and salary.
-- ============================================================================

SELECT
    e.emp_name,
    d.dept_name,
    p.project_name,
    e.salary
FROM Employee AS e
JOIN Department AS d
    ON e.dept_id = d.dept_id
JOIN Project AS p
    ON e.project_id = p.project_id
ORDER BY d.dept_name, e.emp_name;

-- ============================================================================
-- SECTION 12: VERIFY INSERTED RECORD COUNTS
-- These queries confirm that the expected number of rows exists in each table.
-- ============================================================================

SELECT COUNT(*) AS total_departments FROM Department;
SELECT COUNT(*) AS total_projects FROM Project;
SELECT COUNT(*) AS total_employees FROM Employee;

-- ============================================================================
-- RESULT
-- The database contains 5 departments, 8 projects and 30 employees.
-- Selection, Projection, Aggregate Functions, GROUP BY, HAVING, CASE,
-- ORDER BY and JOIN operations have been demonstrated.
-- ============================================================================
