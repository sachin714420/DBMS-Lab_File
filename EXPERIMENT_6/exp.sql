/* ============================================================================
   DBMS LAB - EXPERIMENT 6
   TITLE: STORED PROCEDURES, TRIGGERS, TRANSACTIONS AND SALARY AUDIT
   DBMS: MySQL 8.0+

   AIM
   ---
   To create a stored procedure that transfers an employee between departments,
   validate salary values with triggers, and log salary changes in an audit table.

   IMPORTANT PREREQUISITE
   ---------------------
   Run Experiment 3 first. It creates CompanyDB and the Employee and Department
   tables used by this experiment. This file does not create those base tables.

   BUSINESS RULES
   --------------
   1. Salary must be between 30000 and 150000, inclusive.
   2. An employee transfer requires an existing employee and department.
   3. An employee cannot be transferred to the department they already belong to.
   4. If a stored procedure statement fails, its exception handler rolls back.
   5. A salary audit row is inserted only when the salary actually changes.

   RUNNING NOTES
   -------------
   - Run the file in MySQL 8.0+.
   - Invalid test statements are commented out because they are expected to fail.
   - The successful transfer and salary update change data in CompanyDB.
   ============================================================================ */

USE CompanyDB;

/* SECTION 1: CREATE THE SALARY AUDIT TABLE --------------------------------
   Stores the employee ID, previous salary, new salary, timestamp, and action. */
CREATE TABLE IF NOT EXISTS Employee_Salary_Audit (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    emp_id INT NOT NULL,
    old_salary DECIMAL(10,2),
    new_salary DECIMAL(10,2),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    action VARCHAR(30)
);

/* SECTION 2: REMOVE OLD ROUTINES BEFORE RECREATING THEM --------------------
   DROP ... IF EXISTS makes the script easier to rerun. It removes only the
   triggers and procedure named below, not the Employee or Department tables. */
DROP TRIGGER IF EXISTS validate_employee_salary_insert;
DROP TRIGGER IF EXISTS validate_employee_salary_update;
DROP TRIGGER IF EXISTS audit_salary_update;
DROP PROCEDURE IF EXISTS transfer_employee;

/* SECTION 3: BEFORE INSERT TRIGGER - VALIDATE NEW SALARY -------------------
   NEW.salary means the salary value about to be inserted. SIGNAL rejects an
   invalid value and returns a readable error to the user. */
DELIMITER //
CREATE TRIGGER validate_employee_salary_insert
BEFORE INSERT ON Employee
FOR EACH ROW
BEGIN
    IF NEW.salary < 30000 OR NEW.salary > 150000 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Salary must be between 30000 and 150000';
    END IF;
END//
DELIMITER ;

/* SECTION 4: BEFORE UPDATE TRIGGER - VALIDATE CHANGED SALARY ---------------
   This applies the same salary range rule when an existing employee is updated. */
DELIMITER //
CREATE TRIGGER validate_employee_salary_update
BEFORE UPDATE ON Employee
FOR EACH ROW
BEGIN
    IF NEW.salary < 30000 OR NEW.salary > 150000 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Salary must be between 30000 and 150000';
    END IF;
END//
DELIMITER ;

/* SECTION 5: AFTER UPDATE TRIGGER - AUDIT SALARY CHANGES -------------------
   OLD.salary is the value before the update; NEW.salary is the value after it.
   MySQL's null-safe comparison (<=>) handles NULL values safely. */
DELIMITER //
CREATE TRIGGER audit_salary_update
AFTER UPDATE ON Employee
FOR EACH ROW
BEGIN
    IF NOT (OLD.salary <=> NEW.salary) THEN
        INSERT INTO Employee_Salary_Audit
            (emp_id, old_salary, new_salary, action)
        VALUES
            (NEW.emp_id, OLD.salary, NEW.salary, 'SALARY UPDATE');
    END IF;
END//
DELIMITER ;

/* SECTION 6: STORED PROCEDURE - TRANSFER AN EMPLOYEE -----------------------
   Parameters:
     p_emp_id      : ID of the employee to transfer.
     p_new_dept_id : ID of the destination department.

   Procedure steps:
     1. Start a transaction.
     2. Check that the employee exists.
     3. Check that the destination department exists.
     4. Check that the employee is not already in that department.
     5. Update the department and commit.
     6. If an SQL exception occurs, roll back and re-raise the error. */
DELIMITER //
CREATE PROCEDURE transfer_employee(
    IN p_emp_id INT,
    IN p_new_dept_id INT
)
BEGIN
    DECLARE v_emp_count INT DEFAULT 0;
    DECLARE v_dept_count INT DEFAULT 0;
    DECLARE v_old_dept_id INT;

    /* Error handler: undo the transaction and pass the error back to MySQL. */
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    /* Step 1: Verify that the employee exists. */
    SELECT COUNT(*) INTO v_emp_count
    FROM Employee
    WHERE emp_id = p_emp_id;

    IF v_emp_count = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Employee does not exist';
    END IF;

    /* Step 2: Verify that the destination department exists. */
    SELECT COUNT(*) INTO v_dept_count
    FROM Department
    WHERE dept_id = p_new_dept_id;

    IF v_dept_count = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Department does not exist';
    END IF;

    /* Step 3: Read the employee's current department. */
    SELECT dept_id INTO v_old_dept_id
    FROM Employee
    WHERE emp_id = p_emp_id;

    /* Step 4: Reject a transfer to the same department. */
    IF v_old_dept_id = p_new_dept_id THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Employee is already in this department';
    END IF;

    /* Step 5: Perform the transfer and save the transaction. */
    UPDATE Employee
    SET dept_id = p_new_dept_id
    WHERE emp_id = p_emp_id;

    COMMIT;
END//
DELIMITER ;

/* SECTION 7: TEST A SUCCESSFUL EMPLOYEE TRANSFER ---------------------------
   In the Experiment 3 sample data, employee 6 belongs to department 1 (IT),
   and department 4 is Marketing. This CALL moves employee 6 to Marketing.
   If you rerun it without moving the employee back, the procedure will report
   that the employee is already in the destination department. */
CALL transfer_employee(6, 4);

/* Verify the employee's current department after the transfer. */
SELECT
    e.emp_id,
    e.emp_name,
    d.dept_name
FROM Employee AS e
INNER JOIN Department AS d
    ON e.dept_id = d.dept_id
WHERE e.emp_id = 6;

/* SECTION 8: OPTIONAL EDGE-CASE TESTS --------------------------------------
   Uncomment and execute ONE statement at a time to see the expected error.
   These calls are commented out so the rest of the script can run normally. */

-- Test A: employee ID 99 does not exist; expected error: Employee does not exist.
-- CALL transfer_employee(99, 4);

-- Test B: department ID 99 does not exist; expected error: Department does not exist.
-- CALL transfer_employee(6, 99);

-- Test C: employee 6 is already in department 4 after the successful transfer.
-- Expected error: Employee is already in this department.
-- CALL transfer_employee(6, 4);

/* SECTION 9: TEST SALARY VALIDATION ----------------------------------------
   Invalid example: uncomment and run separately to see the trigger error.
   UPDATE Employee SET salary = 20000 WHERE emp_id = 6;

   Valid example: sets employee 6's salary to 85000. This creates an audit row
   if the salary was different from 85000 before the update. */
UPDATE Employee
SET salary = 85000
WHERE emp_id = 6;

/* SECTION 10: DISPLAY THE SALARY AUDIT LOG --------------------------------
   The audit trigger records the old and new salary when the value changes. */
SELECT
    audit_id,
    emp_id,
    old_salary,
    new_salary,
    changed_at,
    action
FROM Employee_Salary_Audit
ORDER BY audit_id;

/* ============================== END ========================================
   SUMMARY
   - BEFORE INSERT/UPDATE triggers enforce the salary range.
   - AFTER UPDATE trigger records successful salary changes.
   - Stored procedure validates IDs and transfers employees transactionally.
   - ROLLBACK undoes changes after a procedure error; RESIGNAL reports the error.
   ============================================================================ */
