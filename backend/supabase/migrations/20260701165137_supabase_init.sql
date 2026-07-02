--- ENUM TYPES
-- ---------- PostgreSQL Enum Types ----------

CREATE TYPE admission_type AS ENUM (
    'Regular', 
    'Band_Training', 
    'Summer_Camp', 
    'Custom'
);

CREATE TYPE learning_mode AS ENUM (
    'Online', 
    'Offline', 
    'Hybrid'
);

CREATE TYPE department AS ENUM (
    'Music', 
    'Dance', 
    'Acting', 
    'Music_Video_Production', 
    'Other'
);

CREATE TYPE batch AS ENUM (
    'Morning', 
    'Evening'
);

CREATE TYPE education_qualification AS ENUM (
    'Primary_School', 
    'High_School', 
    'Bachelors', 
    'Masters'
);

CREATE TYPE fee_type AS ENUM (
    'Monthly', 
    'Quarterly', 
    'Half_Yearly', 
    'Yearly'
);

CREATE TYPE admission_status AS ENUM (
    'Pending', 
    'Approved', 
    'Declined'
);

CREATE TYPE student_status AS ENUM (
    'pending_payment', 
    'active', 
    'inactive'
);

CREATE TYPE payment_type AS ENUM (
    'admission', 
    'monthly', 
    'quarterly', 
    'half_yearly', 
    'yearly'
);

CREATE TYPE payment_mode AS ENUM (
    'Cash', 
    'UPI', 
    'Card', 
    'Bank_Transfer', 
    'Other'
);

CREATE TYPE payment_status AS ENUM (
    'active', 
    'superseded'
);

-- Note: 'UserRole' description states this is resolved server-side.
CREATE TYPE user_role AS ENUM (
    'anon', 
    'student', 
    'admin'
);

CREATE TYPE student_gender AS ENUM (
    'male', 
    'female', 
    'nonbinary'
);




--- Users Table
CREATE TABLE users (
    user_id UUID Primary Key ,
    user_name TEXT  ,
    role UserRole,
    email TEXT UNIQUE NOT NULL,
    fcm_token TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
);

--- Student Table
CREATE TABLE students(
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(user_id),
    name TEXT NOT NULL,
    admission_type admission_type NOT NULL,
    learning_mode learning_mode NOT NULL,
    department department NOT NULL,
    batch batch NOT NULL,
    education_qualification education_qualification NOT NULL,
    admission_status admission_status NOT NULL,
    status student_status NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    subject TEXT NOT NULL,
    courses TEXT[],
    dob DATE NOT NULL,
    father_name TEXT NOT NULL,
    gender student_gender NOT NULL,
    address TEXT NOT NULL,
    religion TEXT,
    caste TEXT,
    scholar_no TEXT,
    date_of_joining DATE NOT NULL,
    contact TEXT,
    email TEXT NOT NULL,
    fees FLOAT NOT NULL,
    fee_type fee_type NOT NULL,
    fee_paid_till DATE ,
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()

);