/* ============================================================================
   DBMS LAB - EXPERIMENT 7
   TITLE: DATABASE NORMALIZATION (1NF TO BCNF), LOSSLESS JOIN & DEPENDENCY
          PRESERVATION
   DBMS: MySQL 8.0+

   AIM
   ---
   To identify functional dependencies in a denormalized Sales table and
   normalize it step by step from First Normal Form (1NF) to Third Normal Form
   (3NF) and Boyce-Codd Normal Form (BCNF). Verify lossless join and dependency
   preservation using SQL queries.

   BEFORE YOU RUN
   --------------
   1. Execute this file from top to bottom in MySQL Workbench or a compatible tool.
   2. This script automatically creates and selects SalesDB.
   3. Each numbered section builds upon the previous normalization step.

   TABLES USED
   -----------
   Sales(sale_id, sale_date, customer_id, customer_name, salesperson_id,
         salesperson_name, product_id, product_name, quantity)
   Sale_Header(sale_id, sale_date, customer_id, customer_name,
               salesperson_id, salesperson_name)
   Product(product_id, product_name)
   Sale_Item(sale_id, product_id, quantity)
   Customer(customer_id, customer_name)
   Salesperson(salesperson_id, salesperson_name)
   Sale_Header_3NF(sale_id, sale_date, customer_id, salesperson_id)
   ============================================================================ */

CREATE DATABASE IF NOT EXISTS SalesDB;
USE SalesDB;

/* ---------------------------------------------------------------------------
   STEP 1A: CREATE DENORMALIZED TABLE
   PURPOSE: Create the initial denormalized Sales table storing customer,
            salesperson, product, and sales details together.
   KEY IDEA: Storing all attributes in one table introduces data redundancy
             because customer and salesperson details repeat across rows.
   --------------------------------------------------------------------------- */
DROP TABLE IF EXISTS Sales;
CREATE TABLE Sales (
    sale_id INT,
    sale_date DATE,
    customer_id INT,
    customer_name VARCHAR(50),
    salesperson_id INT,
    salesperson_name VARCHAR(50),
    product_id INT,
    product_name VARCHAR(50),
    quantity INT
);

/* ---------------------------------------------------------------------------
   STEP 1B: INSERT SAMPLE RECORDS
   PURPOSE: Populate the denormalized Sales table with six sample records.
   --------------------------------------------------------------------------- */
INSERT INTO Sales VALUES
(1001, '2026-01-10', 1, 'Aarav', 101, 'Rahul', 201, 'Laptop', 1),
(1001, '2026-01-10', 1, 'Aarav', 101, 'Rahul', 202, 'Mouse', 2),
(1002, '2026-01-11', 2, 'Diya', 102, 'Priya', 201, 'Laptop', 1),
(1002, '2026-01-11', 2, 'Diya', 102, 'Priya', 203, 'Keyboard', 1),
(1003, '2026-01-12', 1, 'Aarav', 101, 'Rahul', 202, 'Mouse', 3),
(1003, '2026-01-12', 1, 'Aarav', 101, 'Rahul', 204, 'Monitor', 1);

/* ---------------------------------------------------------------------------
   STEP 1C: DISPLAY DENORMALIZED DATA
   PURPOSE: View all six rows in the unnormalized/denormalized Sales table.
   --------------------------------------------------------------------------- */
SELECT * FROM Sales;

/* ---------------------------------------------------------------------------
   STEP 2: IDENTIFY FUNCTIONAL DEPENDENCIES
   PURPOSE: Document the functional dependencies and candidate key for 1NF.
   KEY IDEA: A functional dependency X -> Y means attribute X uniquely
             determines attribute Y.
   DEPENDENCIES:
   - sale_id -> sale_date, customer_id, salesperson_id
   - customer_id -> customer_name
   - salesperson_id -> salesperson_name
   - product_id -> product_name
   - (sale_id, product_id) -> quantity
   CANDIDATE KEY: (sale_id, product_id)
   --------------------------------------------------------------------------- */

/* ---------------------------------------------------------------------------
   STEP 3: FIRST NORMAL FORM (1NF)
   PURPOSE: Display records ordered by the composite candidate key.
   KEY IDEA: A table is in 1NF when every column holds atomic (single) values
             and there are no repeating groups.
   --------------------------------------------------------------------------- */
SELECT
    sale_id,
    sale_date,
    customer_id,
    customer_name,
    salesperson_id,
    salesperson_name,
    product_id,
    product_name,
    quantity
FROM Sales
ORDER BY sale_id, product_id;

/* ---------------------------------------------------------------------------
   STEP 4A: SECOND NORMAL FORM (2NF) - DECOMPOSE TABLES
   PURPOSE: Remove partial dependencies on the composite key (sale_id, product_id).
   KEY IDEA: Non-key attributes must depend on the entire candidate key, not
             just part of it. Split into Sale_Header, Product, and Sale_Item.
   --------------------------------------------------------------------------- */
DROP TABLE IF EXISTS Sale_Header;
CREATE TABLE Sale_Header AS
SELECT DISTINCT
    sale_id,
    sale_date,
    customer_id,
    customer_name,
    salesperson_id,
    salesperson_name
FROM Sales;

DROP TABLE IF EXISTS Product;
CREATE TABLE Product AS
SELECT DISTINCT
    product_id,
    product_name
FROM Sales;

DROP TABLE IF EXISTS Sale_Item;
CREATE TABLE Sale_Item AS
SELECT
    sale_id,
    product_id,
    quantity
FROM Sales;

/* ---------------------------------------------------------------------------
   STEP 4B: DISPLAY 2NF TABLES
   PURPOSE: Inspect the decomposed 2NF tables (3 headers, 4 products, 6 items).
   --------------------------------------------------------------------------- */
SELECT * FROM Sale_Header ORDER BY sale_id;
SELECT * FROM Product ORDER BY product_id;
SELECT * FROM Sale_Item ORDER BY sale_id, product_id;

/* ---------------------------------------------------------------------------
   STEP 5A: THIRD NORMAL FORM (3NF) - REMOVE TRANSITIVE DEPENDENCIES
   PURPOSE: Extract Customer and Salesperson tables from Sale_Header.
   KEY IDEA: A table is in 3NF when it is in 2NF and no non-key attribute
             depends transitively on the primary key (e.g. sale_id ->
             customer_id -> customer_name).
   --------------------------------------------------------------------------- */
DROP TABLE IF EXISTS Customer;
CREATE TABLE Customer AS
SELECT DISTINCT
    customer_id,
    customer_name
FROM Sale_Header;

DROP TABLE IF EXISTS Salesperson;
CREATE TABLE Salesperson AS
SELECT DISTINCT
    salesperson_id,
    salesperson_name
FROM Sale_Header;

DROP TABLE IF EXISTS Sale_Header_3NF;
CREATE TABLE Sale_Header_3NF AS
SELECT
    sale_id,
    sale_date,
    customer_id,
    salesperson_id
FROM Sale_Header;

/* ---------------------------------------------------------------------------
   STEP 5B: DISPLAY 3NF TABLES
   PURPOSE: Inspect Customer, Salesperson, and Sale_Header_3NF tables.
   --------------------------------------------------------------------------- */
SELECT * FROM Customer ORDER BY customer_id;
SELECT * FROM Salesperson ORDER BY salesperson_id;
SELECT * FROM Sale_Header_3NF ORDER BY sale_id;

/* ---------------------------------------------------------------------------
   STEP 6: VERIFY BOYCE-CODD NORMAL FORM (BCNF)
   PURPOSE: Verify all five decomposed relations satisfy BCNF.
   KEY IDEA: BCNF requires every determinant in every non-trivial functional
             dependency to be a superkey in its respective table.
   --------------------------------------------------------------------------- */
SELECT customer_id, customer_name FROM Customer;
SELECT salesperson_id, salesperson_name FROM Salesperson;
SELECT product_id, product_name FROM Product;
SELECT sale_id, sale_date, customer_id, salesperson_id FROM Sale_Header_3NF;
SELECT sale_id, product_id, quantity FROM Sale_Item;

/* ---------------------------------------------------------------------------
   STEP 7A: VERIFY LOSSLESS JOIN - RECONSTRUCT ORIGINAL DATA
   PURPOSE: Join the normalized tables to reconstruct the original Sales data.
   KEY IDEA: A decomposition is lossless when joining the decomposed tables
             reproduces the exact original rows without spurious tuples.
   --------------------------------------------------------------------------- */
SELECT
    H.sale_id,
    H.sale_date,
    H.customer_id,
    C.customer_name,
    H.salesperson_id,
    SP.salesperson_name,
    P.product_id,
    P.product_name,
    I.quantity
FROM Sale_Header_3NF AS H
INNER JOIN Customer AS C
    ON H.customer_id = C.customer_id
INNER JOIN Salesperson AS SP
    ON H.salesperson_id = SP.salesperson_id
INNER JOIN Sale_Item AS I
    ON H.sale_id = I.sale_id
INNER JOIN Product AS P
    ON I.product_id = P.product_id
ORDER BY H.sale_id, P.product_id;

/* ---------------------------------------------------------------------------
   STEP 7B: VERIFY LOSSLESS JOIN - COMPARE ROW COUNTS
   PURPOSE: Confirm original_rows (6) equals reconstructed_rows (6).
   --------------------------------------------------------------------------- */
SELECT
    (SELECT COUNT(*) FROM Sales) AS original_rows,
    (
        SELECT COUNT(*)
        FROM Sale_Header_3NF AS H
        INNER JOIN Customer AS C ON H.customer_id = C.customer_id
        INNER JOIN Salesperson AS SP ON H.salesperson_id = SP.salesperson_id
        INNER JOIN Sale_Item AS I ON H.sale_id = I.sale_id
        INNER JOIN Product AS P ON I.product_id = P.product_id
    ) AS reconstructed_rows;

/* ---------------------------------------------------------------------------
   STEP 8: VERIFY DEPENDENCY PRESERVATION
   PURPOSE: Check that each identifier uniquely determines its name attribute
            within its own table without requiring joins.
   KEY IDEA: Every determinant maps to a single distinct name (name_count = 1).
   --------------------------------------------------------------------------- */
SELECT
    customer_id,
    COUNT(DISTINCT customer_name) AS name_count
FROM Customer
GROUP BY customer_id;

SELECT
    salesperson_id,
    COUNT(DISTINCT salesperson_name) AS name_count
FROM Salesperson
GROUP BY salesperson_id;

SELECT
    product_id,
    COUNT(DISTINCT product_name) AS name_count
FROM Product
GROUP BY product_id;

/* ============================== END ========================================
   SUMMARY
   - 1NF ensures atomic column values and identifies candidate key (sale_id, product_id).
   - 2NF removes partial dependencies into Sale_Header, Product, and Sale_Item.
   - 3NF removes transitive dependencies into Customer, Salesperson, and Sale_Header_3NF.
   - BCNF holds because every determinant is a candidate key in its table.
   - Lossless join reconstructs all 6 original records without spurious rows.
   - Dependency preservation confirms each FD holds inside a single table.
   ============================================================================ */
