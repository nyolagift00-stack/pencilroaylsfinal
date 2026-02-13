# Pencil Royal

National school competition platform.

## Setup
1. Create Supabase project.
2. Replace URL/key in supabase-client.js.
3. Set up tables: schools, students, competitions, votes, results.
4. Host on Vercel/Netlify.

## Running
Open index.html in browser.

## Features
- School registration & login
- Student management (5 boys, 5 girls per school)
- Admin approval system
- Competition countdown
- Public leaderboard
- Voting system (optional)

## Supabase Tables
- schools (id, name, location, email, approved)
- students (id, school_id, name, gender, age, bio)
- competitions (id, name, start_date, end_date, status)
- results (id, school_id, rank, score)
- votes (id, student_id, voter_id)
