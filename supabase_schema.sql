-- ============================================================
-- OPERATION EFFICIENCY PROJECT (OEP) — SUPABASE SCHEMA (v2)
--
-- DESIGN:
--   Your ORIGINAL data (6 teams, 134 tasks imported from the old
--   tracker) lives hardcoded inside script.js — it is NOT stored
--   in Supabase. This keeps your historical data exactly as it
--   was, with zero risk of it being lost or altered by accident.
--
--   Supabase only stores:
--     1) tasks            -> brand NEW tasks you add going forward
--     2) team_overrides    -> edits you make to the original 6 teams
--     3) task_overrides    -> edits/deletes you make to the original
--                             134 tasks
--
--   On every page load, the app merges:
--     hardcoded teams + team_overrides  =>  final team list
--     hardcoded tasks + task_overrides  =>  final old-task list
--     + new tasks from `tasks`          =>  combined task list
--
-- HOW TO USE:
--   1. Go to your Supabase project → SQL Editor → New Query
--   2. Paste this entire file and click RUN
--   3. Done! Your tables and security are ready.
-- ============================================================


-- ============================================================
-- TABLE 1: TASKS  (NEW tasks created from the app, going forward)
-- ============================================================
CREATE TABLE IF NOT EXISTS tasks (
  id                   TEXT PRIMARY KEY,
  team_code            TEXT NOT NULL,
  team_name            TEXT NOT NULL,
  member               TEXT NOT NULL DEFAULT 'Unassigned',
  title                TEXT NOT NULL,
  description          TEXT DEFAULT '',
  month                TEXT NOT NULL DEFAULT 'January',
  year                 INTEGER NOT NULL DEFAULT 2026,
  fy                   TEXT NOT NULL DEFAULT 'FY 2025-26',
  status               TEXT NOT NULL DEFAULT 'In Progress'
                         CHECK (status IN ('Completed', 'In Progress', 'Delayed')),
  cost_saved           NUMERIC(18,2) DEFAULT 0,
  target_saving        NUMERIC(18,2) DEFAULT 0,
  remarks              TEXT DEFAULT '',
  supporting_doc_name  TEXT DEFAULT '',
  created_at           TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- TABLE 2: TASK_OVERRIDES
-- One row per ORIGINAL (hardcoded) task that has been edited or
-- deleted. `is_deleted = true` hides the original task entirely.
-- Any non-null field below overrides the hardcoded value.
-- ============================================================
CREATE TABLE IF NOT EXISTS task_overrides (
  task_id              TEXT PRIMARY KEY,         -- matches the hardcoded task's id, e.g. 'task-1-2'
  is_deleted           BOOLEAN NOT NULL DEFAULT FALSE,
  team_code            TEXT,
  team_name            TEXT,
  member               TEXT,
  title                TEXT,
  description          TEXT,
  month                TEXT,
  year                 INTEGER,
  fy                   TEXT,
  status               TEXT CHECK (status IN ('Completed', 'In Progress', 'Delayed') OR status IS NULL),
  cost_saved           NUMERIC(18,2),
  target_saving        NUMERIC(18,2),
  remarks              TEXT,
  supporting_doc_name  TEXT,
  updated_at           TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- TABLE 3: TEAM_OVERRIDES
-- One row per ORIGINAL (hardcoded) team that has been edited.
-- Any non-null field below overrides the hardcoded value.
-- ============================================================
CREATE TABLE IF NOT EXISTS team_overrides (
  team_code            TEXT PRIMARY KEY,          -- matches the hardcoded team's code, e.g. 'Team-1'
  name                 TEXT,
  module               TEXT,
  leader               TEXT,
  fy25_expenses        NUMERIC(18,2),
  target_reduction     NUMERIC(18,2),
  cost_saved_25_26     NUMERIC(18,2),
  cost_saved_26_27     NUMERIC(18,2),
  updated_at           TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_tasks_team_code ON tasks(team_code);
CREATE INDEX IF NOT EXISTS idx_tasks_fy        ON tasks(fy);
CREATE INDEX IF NOT EXISTS idx_tasks_status    ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_month     ON tasks(month);

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- Blocks all unauthenticated access. Only logged-in users see data.
-- ============================================================
ALTER TABLE tasks          ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_overrides ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_overrides ENABLE ROW LEVEL SECURITY;

-- Tasks policies
DROP POLICY IF EXISTS "Authenticated users can read tasks"   ON tasks;
DROP POLICY IF EXISTS "Authenticated users can modify tasks" ON tasks;
CREATE POLICY "Authenticated users can read tasks"
  ON tasks FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can modify tasks"
  ON tasks FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Task overrides policies
DROP POLICY IF EXISTS "Authenticated users can read task_overrides"   ON task_overrides;
DROP POLICY IF EXISTS "Authenticated users can modify task_overrides" ON task_overrides;
CREATE POLICY "Authenticated users can read task_overrides"
  ON task_overrides FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can modify task_overrides"
  ON task_overrides FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Team overrides policies
DROP POLICY IF EXISTS "Authenticated users can read team_overrides"   ON team_overrides;
DROP POLICY IF EXISTS "Authenticated users can modify team_overrides" ON team_overrides;
CREATE POLICY "Authenticated users can read team_overrides"
  ON team_overrides FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can modify team_overrides"
  ON team_overrides FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ============================================================
-- VERIFY (optional — run separately to confirm)
-- ============================================================
-- SELECT count(*) FROM tasks;            -- new tasks you've added (starts at 0)
-- SELECT count(*) FROM task_overrides;   -- edits/deletes to old tasks (starts at 0)
-- SELECT count(*) FROM team_overrides;   -- edits to old teams (starts at 0)
