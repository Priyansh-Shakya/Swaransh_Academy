--* Adding ON DELETE SET NULL in students table user_id field.


ALTER TABLE students
ADD CONSTRAINT fk_students_users
FOREIGN KEY (user_id) REFERENCES users(user_id)
ON DELETE SET NULL;