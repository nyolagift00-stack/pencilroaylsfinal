-- Migration: Add sponsors table for admin to manage sponsors

CREATE TABLE sponsors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    logo_url TEXT,
    logo_width INTEGER DEFAULT 150,
    logo_height INTEGER DEFAULT 60,
    position TEXT CHECK (position IN ('top', 'middle', 'bottom')) DEFAULT 'middle',
    display_order INTEGER DEFAULT 0,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX sponsors_position_order ON sponsors(position, display_order);

-- Enable RLS
ALTER TABLE sponsors ENABLE ROW LEVEL SECURITY;

-- Public can read sponsors
CREATE POLICY "sponsors_public_read" ON sponsors
FOR SELECT
USING (active = true);

-- Only admins can insert/update/delete sponsors
CREATE POLICY "sponsors_admin_insert" ON sponsors
FOR INSERT
WITH CHECK (EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin'));

CREATE POLICY "sponsors_admin_update" ON sponsors
FOR UPDATE
USING (EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin'))
WITH CHECK (EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin'));

CREATE POLICY "sponsors_admin_delete" ON sponsors
FOR DELETE
USING (EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin'));

-- Verify
SELECT 'Sponsors table created successfully' as status;
