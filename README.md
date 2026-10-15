# DBMS-Lab_File

DBMS Lab Experiments (1–6)
A clearly organized collection of DBMS lab experiments covering ER modelling, relational schema design, SQL queries, joins, subqueries, views, recursive CTEs, stored procedures, triggers, and audit logging.
Repository Structure
DBMS-Lab-Experiments/
├── Experiment-1-ER-Diagram.pdf
├── Experiment-2-Relational-Schema.pdf
├── Experiment-3-Basic-SQL-Queries.pdf
├── Experiment-4-Joins-Subqueries-Explain.sql
├── Experiment-5-Views-and-Recursive-CTE.sql
├── Experiment-6-Procedures-Triggers-Audit.sql
└── README.md
Experiments at a Glance
Experiment	Topics	File
1	ER diagram for an Indian e-commerce platform	Experiment-1-ER-Diagram.pdf
2	Relational schema, primary/foreign keys, constraints, and referential integrity	Experiment-2-Relational-Schema.pdf
3	Database/table creation, sample records, selection, projection, aggregate functions, GROUP BY, HAVING, CASE, and sorting	Experiment-3-Basic-SQL-Queries.pdf
4	INNER JOIN, LEFT JOIN, self-join, three-table join, correlated subquery, EXISTS, simulated set operations, and EXPLAIN	Experiment-4-Joins-Subqueries-Explain.sql
5	Views, view updatability, employee-manager hierarchy, and recursive CTE	Experiment-5-Views-and-Recursive-CTE.sql
6	Stored procedure, transaction control, error handling, salary-validation triggers, and audit logging	Experiment-6-Procedures-Triggers-Audit.sql


Requirements
- MySQL 8.0 or later.
- MySQL Workbench or another MySQL-compatible SQL editor.
- Run Experiment 3 before Experiments 4 and 6, because they use its CompanyDB, Employee, and Department tables.
- Experiment 5 creates and uses a separate database named ViewCTEDB.
How to Run the SQL Experiments
1. Download or clone this repository.
2. Open the required .sql file in your MySQL editor.
3. Read the comment block at the top of the file before executing it.
4. Run the SQL statements from top to bottom. Each section has a heading and comments explaining its purpose.
5. For Experiment 6, invalid test statements are commented out because they are expected to return errors. Uncomment and execute them individually when testing error handling.
Recommended Order
1. Read Experiment 1 and Experiment 2 PDFs.
2. Complete Experiment 3 to create and populate CompanyDB.
3. Run Experiment 4 to practise joins, subqueries, set operations, and query plans.
4. Run Experiment 5 to practise views and recursive CTEs in ViewCTEDB.
5. Run Experiment 6 to practise procedures and triggers in CompanyDB.
Notes
- Experiments 1–3 are included as PDF lab records. Experiments 4–6 are editable SQL source files with section headings, explanations, and comments.
- Some queries modify data. In Experiment 5, the sample view update adds 5000 to employee 102's salary every time it is executed.
- Experiment 6 transfers employee 6 to department 4 and sets their salary to 85000 in the sample data. Re-running the transfer may trigger the same-department validation error.
- In Experiment 6, the allowed salary range is 30000–150000 inclusive.
- Query output can vary depending on the current database contents and MySQL version.
Author
