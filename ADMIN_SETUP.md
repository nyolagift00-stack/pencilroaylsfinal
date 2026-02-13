# Admin Account Setup Guide

## Overview
The Admin Panel allows you to manage all schools and edit their competition scores without being limited to your own school.

## Pages Created

### 1. **admin-panel.html** - Admin Dashboard
- View all registered schools
- Search/filter schools
- Edit competitions for any school
- View school details

### 2. **admin-intercompitions.html** - Competition Editor
- Edit marks for any school's students
- Select boy/girl finalists
- Save changes to database
- Changes visible in schools.html

## How to Create an Admin Account

### Step 1: Create Admin User Email
1. Get a unique email for your admin account (e.g., `admin@pencilroyal.com`)
2. Make sure it hasn't been used to register a school yet

### Step 2: Sign Up as Regular User
1. Go to `signup.html`
2. Enter admin email and password
3. Fill in school details (can be "Admin" as school name)
4. You'll be logged in and redirected

### Step 3: Mark Account as Admin (In Supabase)
To make this account an admin, run this SQL in Supabase SQL Editor:

```sql
-- Add is_admin column if it doesn't exist
ALTER TABLE schools 
ADD COLUMN is_admin BOOLEAN DEFAULT FALSE;

-- Mark your admin account as admin
UPDATE schools 
SET is_admin = TRUE 
WHERE name = 'Admin';  -- Or match by your school name
```

### Step 4: Access Admin Panel
After marking as admin in Supabase:
1. Log in with admin email/password
2. Go to `http://127.0.0.1:5500/pencil-royal/admin-panel.html`
3. You'll see all schools and can edit their competitions

## Usage Workflow

### As Admin:
1. **View All Schools** - admin-panel.html shows every registered school
2. **Select School** - Click "Edit Competitions" button
3. **Give Marks** - Enter marks (0-100) for students
4. **Select Finalists** - Click ★ to mark boy/girl for nationals
5. **Save Changes** - Click "Save All Changes"
6. Changes are immediately visible in schools.html

### Data Flow:
```
admin-intercompitions.html (Edit)
            ↓
    Supabase Database
    - competition_scores (marks)
    - finalists (selected students)
            ↓
schools.html (View)
school-detail.html (Public view)
```

## Important : RLS Policies

The system uses Row Level Security (RLS) policies. For admin access to work:

1. **Schools table** - Admin should be able to read/edit all schools
2. **Students table** - Admin should be able to read all students
3. **Competition Scores** - Admin should be able to create/update all scores
4. **Finalists table** - Admin should be able to manage finalists

### RLS Policy for Admin Access:

```sql
-- Allow admins to read all schools
CREATE POLICY "Admins can read all schools"
  ON schools FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM schools s2
      WHERE s2.user_id = auth.uid() AND s2.is_admin = TRUE
    )
  );

-- Allow admins to update all schools 
CREATE POLICY "Admins can update all schools"
  ON schools FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM schools s2
      WHERE s2.user_id = auth.uid() AND s2.is_admin = TRUE
    )
  );

-- Similar policies for students, competition_scores, and finalists tables
```

## Navigation

**Add these links to your header/nav:**
```html
<!-- For Regular Users -->
<a href="login.html">Login</a>

<!-- For Admin Users (after login) -->
<a href="admin-panel.html">Admin Panel</a>
```

## Troubleshooting

### "Permission Denied" Error
- Make sure you ran the SQL to mark your account as admin
- Check that the `is_admin` column exists in the schools table

### Can't Access certain schools
- RLS policies may need adjustment
- Check that your user has the `is_admin` flag set to `true`

### Changes not showing in schools.html
- Hard refresh the page (Ctrl+Shift+R)
- Wait a few seconds for Supabase to sync
- Check browser console for errors (F12)

## Features

✅ View all schools without filtering
✅ Edit competitions for any school
✅ Give marks to all students
✅ Select finalists for nationals
✅ Changes sync to schools.html instantly
✅ Search/filter schools in admin panel
✅ Logout functionality
✅ Progress tracking with loader

## Next Steps

1. Create your admin account via signup.html
2. Run the SQL commands above in Supabase
3. Log in and navigate to admin-panel.html
4. Start managing school competitions!

---

**Questions?** Check the browser console (F12) for detailed error messages.
