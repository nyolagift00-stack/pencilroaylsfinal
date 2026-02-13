-- ========================================
-- PENCIL ROYAL - COMPLETE SUPABASE SCHEMA
-- ========================================
-- This schema supports the full Pencil Royal competition platform
-- with schools, students, scores, finalists, and competition management

-- Drop tables in reverse order of dependencies (if they exist from old schema)
DROP TABLE IF EXISTS votes CASCADE;
DROP TABLE IF EXISTS results CASCADE;
DROP TABLE IF EXISTS finalists CASCADE;
DROP TABLE IF EXISTS competition_scores CASCADE;
DROP TABLE IF EXISTS competitions CASCADE;
DROP TABLE IF EXISTS students CASCADE;
DROP TABLE IF EXISTS schools CASCADE;

-- ========================================
-- SCHOOLS TABLE
-- ========================================
-- Stores school information linked to auth users
CREATE TABLE schools (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT,
    location TEXT,
    profile_pic TEXT,
    contact_person TEXT,
    phone TEXT,
    approved BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT valid_school_name CHECK (name != '')
);

-- ========================================
-- STUDENTS TABLE
-- ========================================
-- Stores student records for each school
-- Max 5 boys + 5 girls per school (enforced by application logic)
CREATE TABLE students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    gender TEXT NOT NULL CHECK (gender IN ('male', 'female')),
    age INTEGER CHECK (age >= 5 AND age <= 30),
    profile_pic TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT valid_student_name CHECK (name != '')
);

-- ========================================
-- COMPETITIONS TABLE
-- ========================================
-- Stores internal school competitions and national competitions
CREATE TABLE competitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
    type TEXT CHECK (type IN ('internal', 'national')) DEFAULT 'internal',
    start_date TIMESTAMP WITH TIME ZONE,
    end_date TIMESTAMP WITH TIME ZONE,
    status TEXT CHECK (status IN ('upcoming', 'active', 'completed')) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ========================================
-- COMPETITION SCORES TABLE
-- ========================================
-- Stores individual scores for students in competitions
-- Used for ranking and finalist selection
CREATE TABLE competition_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    competition_id UUID NOT NULL REFERENCES competitions(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    score INTEGER CHECK (score >= 0 AND score <= 100),
    gender TEXT NOT NULL CHECK (gender IN ('male', 'female')),
    rank INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ========================================
-- FINALISTS TABLE
-- ========================================
-- Stores selected finalists (top boy + top girl per school)
-- for national competitions
CREATE TABLE finalists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    competition_id UUID NOT NULL REFERENCES competitions(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    gender TEXT NOT NULL CHECK (gender IN ('male', 'female')),
    score INTEGER,
    status TEXT CHECK (status IN ('qualified', 'competing', 'finished')) DEFAULT 'qualified',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ========================================
-- RESULTS TABLE
-- ========================================
-- Stores final competition results and rankings
CREATE TABLE results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    competition_id UUID REFERENCES competitions(id) ON DELETE CASCADE,
    rank INTEGER,
    score INTEGER,
    total_students INTEGER,
    boys_count INTEGER,
    girls_count INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ========================================
-- VOTES TABLE
-- ========================================
-- Stores votes for students (if needed for voting competitions)
CREATE TABLE votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    voter_id UUID,
    competition_id UUID REFERENCES competitions(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT valid_vote CHECK (voter_id IS NOT NULL)
);

-- ========================================
-- INDEXES FOR PERFORMANCE
-- ========================================
CREATE INDEX idx_schools_user_id ON schools(user_id);
CREATE INDEX idx_students_school_id ON students(school_id);
CREATE INDEX idx_students_gender ON students(gender);
CREATE INDEX idx_competitions_school_id ON competitions(school_id);
CREATE INDEX idx_competition_scores_competition_id ON competition_scores(competition_id);
CREATE INDEX idx_competition_scores_student_id ON competition_scores(student_id);
CREATE INDEX idx_competition_scores_school_id ON competition_scores(school_id);
CREATE INDEX idx_competition_scores_gender ON competition_scores(gender);
CREATE INDEX idx_finalists_competition_id ON finalists(competition_id);
CREATE INDEX idx_finalists_student_id ON finalists(student_id);
CREATE INDEX idx_finalists_school_id ON finalists(school_id);
CREATE INDEX idx_finalists_gender ON finalists(gender);
CREATE INDEX idx_results_school_id ON results(school_id);
CREATE INDEX idx_results_competition_id ON results(competition_id);
CREATE INDEX idx_votes_student_id ON votes(student_id);
CREATE INDEX idx_votes_competition_id ON votes(competition_id);

-- ========================================
-- ENABLE ROW LEVEL SECURITY (RLS)
-- ========================================
ALTER TABLE schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE competitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE competition_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE finalists ENABLE ROW LEVEL SECURITY;
ALTER TABLE results ENABLE ROW LEVEL SECURITY;
ALTER TABLE votes ENABLE ROW LEVEL SECURITY;

-- ========================================
-- ROW LEVEL SECURITY POLICIES
-- ========================================

-- Schools: Users can only see/manage their own school
CREATE POLICY "Users can view own school"
    ON schools FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create school"
    ON schools FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own school"
    ON schools FOR UPDATE
    USING (auth.uid() = user_id);

-- Students: Anyone can view students of any school
CREATE POLICY "Students are viewable by all"
    ON students FOR SELECT
    USING (true);

-- Students: Only school owner can insert/update/delete students
CREATE POLICY "School owner can manage students"
    ON students FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM schools 
            WHERE schools.id = students.school_id 
            AND schools.user_id = auth.uid()
        )
    );

CREATE POLICY "School owner can update students"
    ON students FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM schools 
            WHERE schools.id = students.school_id 
            AND schools.user_id = auth.uid()
        )
    );

CREATE POLICY "School owner can delete students"
    ON students FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM schools 
            WHERE schools.id = students.school_id 
            AND schools.user_id = auth.uid()
        )
    );

-- Competition Scores: Viewable by all (for rankings/leaderboards)
CREATE POLICY "Scores are viewable by all"
    ON competition_scores FOR SELECT
    USING (true);

-- Competition Scores: Only school owner can insert/update
CREATE POLICY "School owner can manage scores"
    ON competition_scores FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM schools 
            WHERE schools.id = competition_scores.school_id 
            AND schools.user_id = auth.uid()
        )
    );

-- Finalists: Viewable by all
CREATE POLICY "Finalists are viewable by all"
    ON finalists FOR SELECT
    USING (true);

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

-- Function to get student count by gender for a school
CREATE OR REPLACE FUNCTION get_student_counts(p_school_id UUID)
RETURNS TABLE (
    total_students INTEGER,
    boys_count INTEGER,
    girls_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as total_students,
        COUNT(*) FILTER (WHERE gender = 'male')::INTEGER as boys_count,
        COUNT(*) FILTER (WHERE gender = 'female')::INTEGER as girls_count
    FROM students
    WHERE school_id = p_school_id;
END;
$$ LANGUAGE plpgsql;

-- Function to get top students overall by average score
CREATE OR REPLACE FUNCTION get_top_students(p_limit INTEGER DEFAULT 10)
RETURNS TABLE (
    student_id UUID,
    student_name TEXT,
    school_id UUID,
    school_name TEXT,
    gender TEXT,
    avg_score NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id,
        s.name,
        s.school_id,
        sch.name,
        s.gender,
        AVG(cs.score)::NUMERIC as avg_score
    FROM students s
    JOIN schools sch ON s.school_id = sch.id
    LEFT JOIN competition_scores cs ON s.id = cs.student_id
    GROUP BY s.id, s.name, s.school_id, sch.name, s.gender
    ORDER BY avg_score DESC NULLS LAST
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Function to get finalists by school
CREATE OR REPLACE FUNCTION get_school_finalists(p_school_id UUID)
RETURNS TABLE (
    student_id UUID,
    student_name TEXT,
    gender TEXT,
    score INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        f.student_id,
        s.name,
        f.gender,
        f.score
    FROM finalists f
    JOIN students s ON f.student_id = s.id
    WHERE f.school_id = p_school_id;
END;
$$ LANGUAGE plpgsql;
