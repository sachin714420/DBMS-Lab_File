# DBMS-Lab_File

A collection of Database Management System (DBMS) laboratory experiments covering ER diagrams, relational schema design, SQL queries, joins, subqueries, views, recursive CTEs, stored procedures, and triggers.

## 📚 Experiments List

| Experiment | Title | File |
|---|---|---|
| 1 | ER Diagram | `Experiment-1-ER-Diagram.pdf` |
| 2 | Relational Schema | `Experiment-2-Relational-Schema.pdf` |
| 3 | Basic SQL Queries | `Experiment-3-Basic-SQL-Queries.pdf` |
| 4 | Joins, Subqueries and EXPLAIN | `Experiment-4-Joins-Subqueries-Explain.sql` |
| 5 | Views and Recursive CTE | `Experiment-5-Views-and-Recursive-CTE.sql` |
| 6 | Stored Procedures and Triggers | `Experiment-6-Procedures-Triggers-Audit.sql` |
| 7 | Database Normalization (1NF to BCNF) | `Experiment-7-Normalization-1NF-to-BCNF.sql` |
| 8 | Transactions, Savepoints and Isolation | `Experiment-8-Transactions-Savepoints-Isolation.sql` |
| 9 | Indexing and Execution Plan Benchmarking | `Experiment-9-Indexing-Explain-Benchmarking.sql` |
| 10 | SQL Query Optimization and EXPLAIN | `Experiment-10-Query-Optimization-Explain.sql` |

## 🎯 Objectives

- Understand database design using ER diagrams.
- Create relational schemas with primary and foreign keys.
- Practice SQL queries and aggregate functions.
- Learn different JOIN operations and subqueries.
- Understand views and recursive Common Table Expressions (CTEs).
- Implement stored procedures, triggers, validation, and audit logging.
- Normalize denormalized tables from 1NF to BCNF and verify lossless join and dependency preservation.
- Implement transactions using `BEGIN`, `COMMIT`, `ROLLBACK`, `SAVEPOINT`, and isolation levels.
- Benchmark query performance before and after creating single-column and composite indexes using `EXPLAIN`.
- Optimize slow SQL queries using indexing and query rewriting techniques.

## 🛠️ Technologies Used

- **Database:** MySQL, PostgreSQL
- **Language:** SQL
- **Version Control:** Git and GitHub

## ⚙️ Requirements

- MySQL 8.0 or later is recommended (for Experiments 3–7 and 9–10).
- PostgreSQL 14 or later / pgAdmin 4 (for Experiment 8).
- MySQL Workbench or another MySQL-compatible SQL client.
- Basic understanding of SQL and relational databases.

## 🚀 How to Run

1. Clone or download this repository.
2. Open the required `.sql` file in MySQL Workbench (or pgAdmin 4 for Experiment 8).
3. Read the comments and section headings before executing the queries.
4. Execute the SQL statements in the order provided.
5. Check the result sets and error messages for the test cases.

### Important Notes

- Experiment 4 uses the `CompanyDB` database and the Employee, Department, and Project tables.
- Experiment 5 creates database objects for views and recursive CTE demonstrations.
- Experiment 6 uses the `CompanyDB` database and the Employee–Department schema.
- Experiment 7 uses the `SalesDB` database to demonstrate normalization from 1NF to BCNF.
- Experiment 8 uses PostgreSQL (`bank_accounts` table) and requires two sessions to demonstrate isolation levels.
- Experiment 9 uses the `RailwayDB` database with 6,000 records to benchmark single-column and composite indexes.
- Experiment 10 uses the `QueryLabDB` database (`EmployeeData` table with 10,000 records) for query optimization.
- Run prerequisite table-creation and data-insertion statements before executing dependent queries.
- Some statements intentionally generate errors to demonstrate validation and error handling.
- Stored procedures, triggers, and recursive CTEs require compatible MySQL syntax.

## 📁 Repository Structure

```text
DBMS-Lab-Experiments/
│
├── README.md
├── Experiment-1-ER-Diagram.pdf
├── Experiment-2-Relational-Schema.pdf
├── Experiment-3-Basic-SQL-Queries.pdf
├── Experiment-4-Joins-Subqueries-Explain.sql
├── Experiment-5-Views-and-Recursive-CTE.sql
├── Experiment-6-Procedures-Triggers-Audit.sql
├── Experiment-7-Normalization-1NF-to-BCNF.sql
├── Experiment-8-Transactions-Savepoints-Isolation.sql
├── Experiment-9-Indexing-Explain-Benchmarking.sql
└── Experiment-10-Query-Optimization-Explain.sql
```

## 📖 Learning Outcomes

After completing these experiments, students will gain practical experience in relational database design, SQL querying, data relationships, views, subqueries, stored procedures, triggers, database normalization, transaction management, indexing, query optimization, and database error handling.

## 👨‍💻 Author

**Sachin Vishwakarma**

B.Tech CSE – Artificial Intelligence and Machine Learning

---

⭐ This repository is maintained for DBMS laboratory practice and learning.
