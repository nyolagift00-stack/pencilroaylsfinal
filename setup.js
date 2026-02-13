// Setup script to create database tables
const SUPABASE_URL = 'https://tjooofnjwwtgageayezr.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRqb29vZm5qd3d0Z2FnZWF5ZXpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA0NTI1NDIsImV4cCI6MjA4NjAyODU0Mn0.Pg8ldP8qI6e70WNGNzdnAbMmgAlL1rb6w41sGjXFc9Y';

const supabaseUrl = SUPABASE_URL;
const supabaseKey = SUPABASE_ANON_KEY;

const sql = `
-- Create schools table
CREATE TABLE IF NOT EXISTS schools (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT,
    location TEXT,
    profile_pic TEXT,
    contact_person TEXT,
    phone TEXT,
    approved BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Create students table
CREATE TABLE IF NOT EXISTS students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    gender TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Create competitions table
CREATE TABLE IF NOT EXISTS competitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    start_date TIMESTAMP,
    end_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Create results table
CREATE TABLE IF NOT EXISTS results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    rank INTEGER,
    score INTEGER,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Create votes table
CREATE TABLE IF NOT EXISTS votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    voter_id UUID,
    created_at TIMESTAMP DEFAULT NOW()
);
`;

console.log('✓ Database schema prepared');
console.log('\n📋 TO COMPLETE SETUP:\n');
console.log('1. Go to: https://app.supabase.com/project/tjooofnjwwtgageayezr/sql/new');
console.log('2. Copy the SQL above ↑');
console.log('3. Paste it in the Supabase SQL Editor');
console.log('4. Click "Run" button');
console.log('\n✅ Once done, your app will work!');
