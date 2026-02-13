-- ========================================
-- National Competition Management Schema
-- ========================================
-- Adds support for admin to assign schools to positions,
-- create tournament brackets, and manage matchups for national competitions

-- ========================================
-- NATIONAL COMPETITION POSITIONS TABLE
-- ========================================
-- Stores position assignments for schools in national competitions
-- Admin assigns schools to specific positions (1, 2, 3, etc.)
CREATE TABLE IF NOT EXISTS national_positions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    competition_id UUID NOT NULL REFERENCES competitions(id) ON DELETE CASCADE,
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    position INTEGER NOT NULL,
    seeding_score INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(competition_id, school_id),
    UNIQUE(competition_id, position)
);

-- ========================================
-- MATCHUPS/BRACKET TABLE
-- ========================================
-- Stores tournament bracket matchups (e.g., Position 1 vs Position 2)
CREATE TABLE IF NOT EXISTS matchups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    competition_id UUID NOT NULL REFERENCES competitions(id) ON DELETE CASCADE,
    round INTEGER NOT NULL,
    matchup_number INTEGER NOT NULL,
    team1_position INTEGER,
    team2_position INTEGER,
    team1_school_id UUID REFERENCES schools(id) ON DELETE SET NULL,
    team2_school_id UUID REFERENCES schools(id) ON DELETE SET NULL,
    winner_school_id UUID REFERENCES schools(id) ON DELETE SET NULL,
    team1_score INTEGER,
    team2_score INTEGER,
    status TEXT CHECK (status IN ('scheduled', 'ongoing', 'completed')) DEFAULT 'scheduled',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(competition_id, round, matchup_number)
);

-- ========================================
-- NATIONAL COMPETITION RESULTS TABLE
-- ========================================
-- Stores final rankings and results for national competitions
CREATE TABLE IF NOT EXISTS national_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    competition_id UUID NOT NULL REFERENCES competitions(id) ON DELETE CASCADE,
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    rank INTEGER NOT NULL,
    score INTEGER,
    wins INTEGER DEFAULT 0,
    losses INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(competition_id, school_id),
    UNIQUE(competition_id, rank)
);

-- ========================================
-- INDEXES FOR PERFORMANCE
-- ========================================
CREATE INDEX idx_national_positions_competition ON national_positions(competition_id);
CREATE INDEX idx_national_positions_school ON national_positions(school_id);
CREATE INDEX idx_matchups_competition ON matchups(competition_id);
CREATE INDEX idx_matchups_round ON matchups(competition_id, round);
CREATE INDEX idx_national_results_competition ON national_results(competition_id);
CREATE INDEX idx_national_results_school ON national_results(school_id);

-- ========================================
-- ENABLE ROW LEVEL SECURITY
-- ========================================
ALTER TABLE national_positions ENABLE ROW LEVEL SECURITY;
ALTER TABLE matchups ENABLE ROW LEVEL SECURITY;
ALTER TABLE national_results ENABLE ROW LEVEL SECURITY;

-- ========================================
-- ROW LEVEL SECURITY POLICIES
-- ========================================
-- National Positions: Viewable by all, editable by admin only
CREATE POLICY "National positions viewable by all"
    ON national_positions FOR SELECT
    USING (true);

-- Matchups: Viewable by all
CREATE POLICY "Matchups viewable by all"
    ON matchups FOR SELECT
    USING (true);

-- National Results: Viewable by all
CREATE POLICY "National results viewable by all"
    ON national_results FOR SELECT
    USING (true);
