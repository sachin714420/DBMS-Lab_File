/* ============================================================================
   DBMS LAB - EXPERIMENT 8
   TITLE: TRANSACTION MANAGEMENT (BEGIN, COMMIT, ROLLBACK, SAVEPOINT) &
          ISOLATION LEVELS
   DBMS: PostgreSQL 14+

   AIM
   ---
   To implement banking-style transactions using BEGIN, COMMIT, ROLLBACK, and
   SAVEPOINT in SQL, simulate partial failures, and demonstrate isolation levels
   and concurrency anomalies using two database sessions.

   BEFORE YOU RUN
   --------------
   1. Execute Sections A through E sequentially in pgAdmin 4 or psql.
   2. Section F requires two separate database sessions (Session 1 & Session 2)
      to demonstrate concurrency control and isolation levels.

   TABLES USED
   -----------
   bank_accounts(account_id, account_holder, balance)
   ============================================================================ */

/* ---------------------------------------------------------------------------
   SECTION A: CREATE THE BANK ACCOUNTS TABLE
   PURPOSE: Create bank_accounts with a non-negative balance constraint and
            insert initial balances for Rahul and Aman.
   KEY IDEA: CHECK (balance >= 0) enforces domain integrity at the database level.
   --------------------------------------------------------------------------- */
DROP TABLE IF EXISTS bank_accounts;
CREATE TABLE bank_accounts (
    account_id INT PRIMARY KEY,
    account_holder VARCHAR(50),
    balance NUMERIC(12, 2) CHECK (balance >= 0)
);

INSERT INTO bank_accounts VALUES
(101, 'Rahul', 10000.00),
(102, 'Aman', 5000.00);

SELECT * FROM bank_accounts;

/* ---------------------------------------------------------------------------
   SECTION B: DEMONSTRATE BEGIN AND COMMIT
   PURPOSE: Transfer Rs. 2,000 from Rahul (101) to Aman (102) atomically.
   KEY IDEA: BEGIN starts a transaction block and COMMIT makes all changes
             permanent so either both updates succeed or neither does.
   --------------------------------------------------------------------------- */
BEGIN;

UPDATE bank_accounts
SET balance = balance - 2000
WHERE account_id = 101;

UPDATE bank_accounts
SET balance = balance + 2000
WHERE account_id = 102;

COMMIT;

SELECT * FROM bank_accounts;

/* ---------------------------------------------------------------------------
   SECTION C: DEMONSTRATE ROLLBACK
   PURPOSE: Withdraw Rs. 1,000 from Rahul's account and cancel the transaction.
   KEY IDEA: ROLLBACK undoes all uncommitted changes within the current
             transaction and restores the previous consistent state.
   --------------------------------------------------------------------------- */
BEGIN;

UPDATE bank_accounts
SET balance = balance - 1000
WHERE account_id = 101;

SELECT * FROM bank_accounts;

ROLLBACK;

SELECT * FROM bank_accounts;

/* ---------------------------------------------------------------------------
   SECTION D: DEMONSTRATE SAVEPOINT
   PURPOSE: Recover from a partial failure inside a multi-step transaction.
   KEY IDEA: SAVEPOINT marks an intermediate point; ROLLBACK TO SAVEPOINT undoes
             subsequent statements while preserving earlier changes.
   --------------------------------------------------------------------------- */
BEGIN;

UPDATE bank_accounts
SET balance = balance - 500
WHERE account_id = 101;

SAVEPOINT sp1;

UPDATE bank_accounts
SET balance = balance - 20000
WHERE account_id = 101;

ROLLBACK TO SAVEPOINT sp1;

UPDATE bank_accounts
SET balance = balance + 500
WHERE account_id = 102;

COMMIT;

SELECT * FROM bank_accounts;

/* ---------------------------------------------------------------------------
   SECTION E: DEMONSTRATE TRANSACTION ISOLATION
   PURPOSE: Execute a read transaction under the SERIALIZABLE isolation level.
   KEY IDEA: SERIALIZABLE is PostgreSQL's strictest isolation level, ensuring
             concurrent transactions behave as if executed sequentially.
   --------------------------------------------------------------------------- */
START TRANSACTION;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SELECT * FROM bank_accounts;

COMMIT;

/* ---------------------------------------------------------------------------
   SECTION F: CONCURRENCY ANOMALIES USING TWO SESSIONS
   PURPOSE: Observe dirty read prevention and non-repeatable reads across two
            separate query windows (Session 1 and Session 2).
   KEY IDEA: Under READ COMMITTED, Session 2 only sees committed data, preventing
             dirty reads, while re-reading after Session 1 commits shows the
             updated value (non-repeatable read).
   --------------------------------------------------------------------------- */

-- [SESSION 1 - STEP 1] Update Rahul's balance without committing
BEGIN;
UPDATE bank_accounts
SET balance = 9000
WHERE account_id = 101;
-- Do not commit yet.

-- [SESSION 2 - STEP 2] Read balance under READ COMMITTED (sees 7500.00, no dirty read)
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT balance
FROM bank_accounts
WHERE account_id = 101;

-- [SESSION 1 - STEP 3] Commit the updated balance
COMMIT;

-- [SESSION 2 - STEP 4] Re-read balance in same transaction (now sees 9000.00)
SELECT balance
FROM bank_accounts
WHERE account_id = 101;
COMMIT;

/* ============================== END ========================================
   SUMMARY
   - BEGIN starts an explicit transaction block.
   - COMMIT permanently saves all changes made in the transaction.
   - ROLLBACK cancels uncommitted changes and restores the prior state.
   - SAVEPOINT enables partial rollback without aborting the entire transaction.
   - Isolation levels (READ COMMITTED, REPEATABLE READ, SERIALIZABLE) control
     concurrent read/write visibility and prevent concurrency anomalies.
   ============================================================================ */
