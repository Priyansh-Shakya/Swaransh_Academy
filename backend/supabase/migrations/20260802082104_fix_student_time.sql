
--* Update Student table's fields
ALTER TABLE students
ALTER COLUMN start_time TYPE TIME
USING start_time::time;

ALTER TABLE students
ALTER COLUMN end_time TYPE TIME
USING end_time::time;


--* Update Admission table's fields
ALTER TABLE admissions
ALTER COLUMN start_time TYPE TIME
USING start_time::time;

ALTER TABLE admissions
ALTER COLUMN end_time TYPE TIME
USING end_time::time;
