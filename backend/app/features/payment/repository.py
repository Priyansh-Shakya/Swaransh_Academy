"""Repository for Payment data access"""

# Create payment record
create_payment_query = """
INSERT INTO payment (student_id, payment_type, amount, mode, txn_ref, paid_on, status , payment_category , isActive)
VALUES ($1, $2, $3, $4, $5, COALESCE($6, now()), $7, $8, $9)
RETURNING *;
"""

# Get payment by ID
get_payment_by_id_query = """
SELECT * FROM payment WHERE id = $1;
"""

# Get all payments for a student
get_payments_by_student_query = """
SELECT * FROM payment WHERE student_id = $1 ORDER BY paid_on DESC;
"""

# Update payment status (for superseding)
supersede_payment_query = """
UPDATE payment SET status = 'superseded', superseded_by = $1 WHERE id = $2 RETURNING *;
"""

# Insert new payment (as part of supersede pattern)
create_corrected_payment_query = """
INSERT INTO payment (student_id, payment_type, amount, mode, txn_ref, paid_on, status, payment_category)
VALUES ($1, $2, $3, $4, $5, COALESCE($6, now()), 'active' , $7)
RETURNING *;
"""

# Delete payment (hard delete for genuine duplicates)
delete_payment_query = """
DELETE FROM payment WHERE id = $1;
"""

# Get all payments (admin view)
get_all_payments_query = """
SELECT * FROM payment ORDER BY paid_on DESC;
"""

# Update student's fee_paid_till
update_student_fee_paid_till_query = """
UPDATE students SET fee_paid_till = $1 WHERE id = $2 RETURNING fee_paid_till;
"""
