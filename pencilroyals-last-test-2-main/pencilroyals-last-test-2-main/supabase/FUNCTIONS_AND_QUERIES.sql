-- ========================================
-- PENCIL ROYAL - COMPLETE SQL FUNCTIONS & PROCEDURES
-- ========================================
-- Copy and paste these directly into your Supabase SQL Editor

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

-- Function 1: Get student counts by gender for a school
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

-- Usage:
-- SELECT * FROM get_student_counts('550e8400-e29b-41d4-a716-446655440000');


-- Function 2: Get top students overall by average score
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

-- Usage:
-- SELECT * FROM get_top_students(10);  -- Get top 10 students
-- SELECT * FROM get_top_students(5);   -- Get top 5 students


-- Function 3: Get finalists by school
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

-- Usage:
-- SELECT * FROM get_school_finalists('550e8400-e29b-41d4-a716-446655440000');


-- ========================================
-- USEFUL STORED PROCEDURES
-- ========================================

-- Procedure 1: Get school profile with student statistics
CREATE OR REPLACE FUNCTION get_school_profile(p_school_id UUID)
RETURNS TABLE (
    school_id UUID,
    school_name TEXT,
    location TEXT,
    contact_person TEXT,
    phone TEXT,
    profile_pic TEXT,
    total_students INTEGER,
    boys_count INTEGER,
    girls_count INTEGER,
    approved BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id,
        s.name,
        s.location,
        s.contact_person,
        s.phone,
        s.profile_pic,
        COUNT(st.id)::INTEGER,
        COUNT(st.id) FILTER (WHERE st.gender = 'male')::INTEGER,
        COUNT(st.id) FILTER (WHERE st.gender = 'female')::INTEGER,
        s.approved
    FROM schools s
    LEFT JOIN students st ON s.id = st.school_id
    WHERE s.id = p_school_id
    GROUP BY s.id;
END;
$$ LANGUAGE plpgsql;

-- Usage:
-- SELECT * FROM get_school_profile('550e8400-e29b-41d4-a716-446655440000');


-- Procedure 2: Get competition leaderboard
CREATE OR REPLACE FUNCTION get_competition_leaderboard(p_competition_id UUID)
RETURNS TABLE (
    rank INTEGER,
    student_name TEXT,
    school_name TEXT,
    gender TEXT,
    score INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cs.rank,
        st.name,
        sch.name,
        cs.gender,
        cs.score
    FROM competition_scores cs
    JOIN students st ON cs.student_id = st.id
    JOIN schools sch ON cs.school_id = sch.id
    WHERE cs.competition_id = p_competition_id
    ORDER BY cs.rank ASC;
END;
$$ LANGUAGE plpgsql;

-- Usage:
-- SELECT * FROM get_competition_leaderboard('50e8400-e29b-41d4-a716-446655440000');


-- Procedure 3: Get all schools with student counts
CREATE OR REPLACE FUNCTION get_all_schools_summary()
RETURNS TABLE (
    school_id UUID,
    school_name TEXT,
    location TEXT,
    profile_pic TEXT,
    total_students INTEGER,
    boys_count INTEGER,
    girls_count INTEGER,
    approved BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id,
        s.name,
        s.location,
        s.profile_pic,
        COUNT(st.id)::INTEGER,
        COUNT(st.id) FILTER (WHERE st.gender = 'male')::INTEGER,
        COUNT(st.id) FILTER (WHERE st.gender = 'female')::INTEGER,
        s.approved
    FROM schools s
    LEFT JOIN students st ON s.id = st.school_id
    GROUP BY s.id, s.name, s.location, s.profile_pic, s.approved
    ORDER BY s.name;
END;
$$ LANGUAGE plpgsql;

-- Usage:
-- SELECT * FROM get_all_schools_summary();


-- ========================================
-- HELPFUL QUERY TEMPLATES
-- ========================================

-- Query 1: Show all schools with their details
-- SELECT 
--     id, name, location, contact_person, phone, approved, created_at
-- FROM schools
-- ORDER BY name;


-- Query 2: Show all students in a school
-- SELECT 
--     id, name, gender, age, profile_pic, created_at
-- FROM students
-- WHERE school_id = '[SCHOOL_ID_HERE]'
-- ORDER BY name;


-- Query 3: Show students by gender
-- SELECT 
--     gender,
--     COUNT(*) as count
-- FROM students
-- WHERE school_id = '[SCHOOL_ID_HERE]'
-- GROUP BY gender;


-- Query 4: Show all competitions
-- SELECT 
--     id, name, type, status, start_date, end_date, created_at
-- FROM competitions
-- ORDER BY created_at DESC;


-- Query 5: Show scores for a specific competition
-- SELECT 
--     cs.rank,
--     st.name as student_name,
--     sch.name as school_name,
--     cs.score,
--     cs.gender
-- FROM competition_scores cs
-- JOIN students st ON cs.student_id = st.id
-- JOIN schools sch ON cs.school_id = sch.id
-- WHERE cs.competition_id = '[COMPETITION_ID_HERE]'
-- ORDER BY cs.rank;


-- Query 6: Show finalists
-- SELECT 
--     f.id,
--     st.name as student_name,
--     sch.name as school_name,
--     f.gender,
--     f.score,
--     f.status
-- FROM finalists f
-- JOIN students st ON f.student_id = st.id
-- JOIN schools sch ON f.school_id = sch.id
-- ORDER BY f.gender, f.score DESC;


-- Query 7: Show competition results
-- SELECT 
--     r.rank,
--     sch.name as school_name,
--     r.score,
--     r.total_students,
--     r.boys_count,
--     r.girls_count
-- FROM results r
-- JOIN schools sch ON r.school_id = sch.id
-- ORDER BY r.rank;


-- Query 8: Show top 10 students by average score
-- SELECT 
--     st.name as student_name,
--     sch.name as school_name,
--     st.gender,
--     AVG(cs.score) as avg_score,
--     COUNT(cs.id) as competition_count
-- FROM students st
-- JOIN schools sch ON st.school_id = sch.id
-- LEFT JOIN competition_scores cs ON st.id = cs.student_id
-- GROUP BY st.id, st.name, sch.name, st.gender
-- ORDER BY avg_score DESC
-- LIMIT 10;


-- Query 9: Show students without profile pictures
-- SELECT 
--     id, name, school_id, gender
-- FROM students
-- WHERE profile_pic IS NULL
-- ORDER BY name;


-- Query 10: Show schools without profile pictures
-- SELECT 
--     id, name, location
-- FROM schools
-- WHERE profile_pic IS NULL
-- ORDER BY name;


-- ========================================
-- PROFILE PICTURE MANAGEMENT SQL
-- ========================================

-- Update school profile picture with Base64
-- UPDATE schools 
-- SET profile_pic = 'data:image/jpeg;base64,[BASE64_DATA_HERE]'
-- WHERE id = '[SCHOOL_ID_HERE]';


-- Update student profile picture with Base64
-- UPDATE students 
-- SET profile_pic = 'data:image/jpeg;base64,[BASE64_DATA_HERE]'
-- WHERE id = '[STUDENT_ID_HERE]';


-- Get school profile picture
-- SELECT id, name, profile_pic FROM schools WHERE id = '[SCHOOL_ID_HERE]';


-- Get student profile picture
-- SELECT id, name, profile_pic FROM students WHERE id = '[STUDENT_ID_HERE]';


-- Delete profile picture (set to NULL)
-- UPDATE schools SET profile_pic = NULL WHERE id = '[SCHOOL_ID_HERE]';
-- UPDATE students SET profile_pic = NULL WHERE id = '[STUDENT_ID_HERE]';


-- ========================================
-- MIGRATION & MAINTENANCE
-- ========================================

-- Check database size statistics
-- SELECT 
--     schemaname,
--     tablename,
--     pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
-- FROM pg_tables
-- WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
-- ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;


-- Count records in each table
-- SELECT 
--     'schools' as table_name, COUNT(*) as count FROM schools
-- UNION ALL SELECT 'students', COUNT(*) FROM students
-- UNION ALL SELECT 'competitions', COUNT(*) FROM competitions
-- UNION ALL SELECT 'competition_scores', COUNT(*) FROM competition_scores
-- UNION ALL SELECT 'finalists', COUNT(*) FROM finalists
-- UNION ALL SELECT 'results', COUNT(*) FROM results
-- UNION ALL SELECT 'votes', COUNT(*) FROM votes;


-- Analyze data distribution
-- SELECT 
--     'Schools' as entity,
--     COUNT(*) as total,
--     COUNT(CASE WHEN approved THEN 1 END) as approved,
--     COUNT(CASE WHEN approved IS FALSE THEN 1 END) as unapproved
-- FROM schools;


