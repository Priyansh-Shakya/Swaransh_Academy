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

CREATE TYPE course_tag AS ENUM(
    'Vocal',
    'Instrumental'
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

CREATE TYPE payment_cat AS ENUM (
    'fee',
    'admission',
    'other'
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
    'guest', 
    'student', 
    'admin'
);

CREATE TYPE student_gender AS ENUM (
    'male', 
    'female', 
    'non-binary'
);




--- Users Table
CREATE TABLE users (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    user_name TEXT  ,
    role user_role Not NULL DEFAULT 'guest',
    email TEXT  NOT NULL,
    fcm_token TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

--- Courses Table
CREATE TABLE courses(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    course_name TEXT NOT NULL,
    duration TEXT NOT NULL,
    fees BIGINT NOT NULL,
    mode learning_mode DEFAULT 'Offline',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() ,
    tag  course_tag NOT NULL,
    maps_to_department department NOT NULL,
    maps_to_subject TEXT NOT NULL,
    image_url TEXT
);

--- Student Table
CREATE TABLE students(
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(user_id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    admission_type admission_type NOT NULL,
    learning_mode learning_mode NOT NULL,
    department department NOT NULL,
    batch batch NOT NULL,
    education_qualification education_qualification NOT NULL,
    admission_status admission_status NOT NULL,
    status student_status NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
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

-- UNIQUE Scholar Number Constraint
ALTER TABLE students
ADD CONSTRAINT uq_students_scholar_no
UNIQUE (scholar_no);



CREATE TABLE payment (
    -- Modern 8-byte auto-incrementing BIGINT primary key
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    
    -- References standard 8-byte student ID (Assumes students.id is also BIGINT)
    student_id BIGINT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    
    payment_type payment_type NOT NULL,
    payment_category payment_cat NOT NULL,
    isActive boolean DEFAULT true,
    amount BIGINT NOT NULL, -- Stored in minor units (e.g., cents)
    mode payment_mode NOT NULL,
    txn_ref TEXT,
    
    -- Fixed: Uses correct timestamp with time zone tracking
    paid_on TIMESTAMPTZ DEFAULT now(),
    
    status payment_status DEFAULT 'active',
    
    -- Fixed: Matches the 8-byte 'id' column for self-referencing ledger updates
    superseded_by BIGINT REFERENCES payment(id) ON DELETE SET NULL
);


--- Admissions TABLE
CREATE TABLE admissions (
    -- Auto-incrementing 8-byte ID matching your student ID scale
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    
    -- Bound server-side from JWT; NULL if submitted anonymously
    user_id UUID not null REFERENCES users(user_id) ON DELETE CASCADE,
    
    -- Core Application Lifecycle Status
    status admission_status NOT NULL DEFAULT 'Pending',
    
    -- Basic Student Profile Fields
    name TEXT NOT NULL,
    dob DATE NOT NULL,
    gender student_gender NOT NULL,
    father_name TEXT NOT NULL,
    education_qualification education_qualification NOT NULL,
    
    -- Contact & Address Information
    contact TEXT NOT NULL,
    email TEXT NOT NULL, -- Becomes their future login key once approved
    address TEXT NOT NULL,
    religion TEXT,
    caste TEXT,
    
    -- Course Enrollment Details
    admission_type admission_type NOT NULL,
    learning_mode learning_mode NOT NULL,
    department department NOT NULL,
    batch batch NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    subject TEXT NOT NULL,
    
    -- Stores the full array of course objects defined in your YAML contract
    courses Text[],
    
    -- Financials: Upgraded from float to exact decimal precision
    fees NUMERIC(10, 2) NOT NULL,
    fee_type fee_type NOT NULL,
    
    -- Audit Tracking Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Performance Indexing for common search/administrative flows
CREATE INDEX idx_admissions_status ON admissions(status);
CREATE INDEX idx_admissions_email ON admissions(email);
CREATE INDEX idx_admissions_user_id ON admissions(user_id) WHERE user_id IS NOT NULL;
