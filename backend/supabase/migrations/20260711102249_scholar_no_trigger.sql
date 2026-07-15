
-- Generates  a Sequence of number
CREATE SEQUENCE scholar_no_seq
START WITH 1
INCREMENT BY 1;


--- Trigger Function
CREATE OR REPLACE FUNCTION generate_scholar_no()
RETURNS TRIGGER AS
$$
BEGIN
    -- Only generate if not supplied
    IF NEW.scholar_no IS NULL THEN
        NEW.scholar_no :=
    'SCH' ||
    to_char(NEW.date_of_joining, 'YY') ||
    LPAD(nextval('scholar_no_seq')::text, 6, '0');
    END IF;

    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

-- Attach trigger to Students Table
CREATE TRIGGER trg_generate_scholar_no
BEFORE INSERT
ON students
FOR EACH ROW
EXECUTE FUNCTION generate_scholar_no();