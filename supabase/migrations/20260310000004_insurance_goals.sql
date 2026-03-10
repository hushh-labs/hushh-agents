-- ============================================================
-- Migration: Insurance Goals + Goal Attributes
-- Supports: S6 (Coverage Goals / Intent)
-- ============================================================

CREATE TABLE IF NOT EXISTS insurance_goals (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email           TEXT NOT NULL,
  goal            TEXT NOT NULL,
  is_primary      BOOLEAN DEFAULT false,
  intent_status   TEXT DEFAULT 'active' CHECK (intent_status IN ('active', 'exploratory')),
  timeline        TEXT CHECK (timeline IN ('now', 'this_month', 'researching')),
  communication_style TEXT CHECK (communication_style IN ('fast_answers', 'deep_planning', 'ongoing_relationship')),
  language_pref   TEXT DEFAULT 'en',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_insurance_goals_email ON insurance_goals(email);

CREATE TABLE IF NOT EXISTS goal_attributes (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  goal_id         UUID REFERENCES insurance_goals(id) ON DELETE CASCADE,
  attribute_key   TEXT NOT NULL,
  attribute_value TEXT NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trigger_insurance_goals_updated_at
  BEFORE UPDATE ON insurance_goals
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

ALTER TABLE insurance_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE goal_attributes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role full access on insurance_goals"
  ON insurance_goals FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Service role full access on goal_attributes"
  ON goal_attributes FOR ALL USING (true) WITH CHECK (true);
