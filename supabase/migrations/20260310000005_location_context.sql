-- ============================================================
-- Migration: Location Preferences + Insurance Context
-- Supports: S7 (Location & Communication Preferences)
-- ============================================================

CREATE TABLE IF NOT EXISTS location_preferences (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email           TEXT UNIQUE NOT NULL,
  location_source TEXT DEFAULT 'zip' CHECK (location_source IN ('gps', 'zip', 'none')),
  latitude        DOUBLE PRECISION,
  longitude       DOUBLE PRECISION,
  zip_code        TEXT,
  comm_prefs      TEXT[] DEFAULT '{}',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS insurance_context (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email           TEXT UNIQUE NOT NULL,
  timeline        TEXT CHECK (timeline IN ('now', 'this_week', 'this_month', 'researching')),
  insured_status  TEXT CHECK (insured_status IN ('insured', 'uninsured', 'switching', 'unsure')),
  household_size  TEXT CHECK (household_size IN ('individual', 'couple', 'family_small', 'family_large', 'business')),
  current_carrier TEXT,
  context_json    JSONB DEFAULT '{}',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_location_prefs_email ON location_preferences(email);
CREATE INDEX IF NOT EXISTS idx_insurance_context_email ON insurance_context(email);

CREATE TRIGGER trigger_location_prefs_updated_at
  BEFORE UPDATE ON location_preferences
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_insurance_context_updated_at
  BEFORE UPDATE ON insurance_context
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

ALTER TABLE location_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE insurance_context ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role full access on location_preferences"
  ON location_preferences FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Service role full access on insurance_context"
  ON insurance_context FOR ALL USING (true) WITH CHECK (true);
