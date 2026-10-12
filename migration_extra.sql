-- ============================================================================
-- Wellness Tracker - extra SQL for the first migration
-- Append this to the END of the migration.sql before applying it.
-- Prisma cannot express these rules, so they are added by hand.
-- ============================================================================

-- 1. Link profiles to Supabase Auth. Deleting the auth user deletes the profile
--    (and, through the other cascades, all of that user's data).
--    The IF EXISTS guard lets the same migration also run on a plain Postgres
--    database that has no auth schema (for example Prisma's shadow database).
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'auth' AND table_name = 'users'
  ) THEN
    ALTER TABLE "profiles"
      ADD CONSTRAINT "profiles_id_fkey"
      FOREIGN KEY ("id") REFERENCES auth.users("id") ON DELETE CASCADE;
  END IF;
END $$;

-- 2. Value checks from the Database Design PDF
--    (the API also rejects a birth year in the future)
ALTER TABLE "profiles"
  ADD CONSTRAINT "profiles_birth_year_range"
  CHECK ("birth_year" IS NULL OR "birth_year" BETWEEN 1900 AND 2100);

ALTER TABLE "water_logs"
  ADD CONSTRAINT "water_logs_amount_ml_positive" CHECK ("amount_ml" > 0);

ALTER TABLE "exercise_logs"
  ADD CONSTRAINT "exercise_logs_duration_min_positive" CHECK ("duration_min" > 0);

ALTER TABLE "sleep_logs"
  ADD CONSTRAINT "sleep_logs_wake_after_bed" CHECK ("wake_time" > "bed_time");

ALTER TABLE "sleep_logs"
  ADD CONSTRAINT "sleep_logs_quality_range" CHECK ("quality" BETWEEN 1 AND 5);

ALTER TABLE "mood_logs"
  ADD CONSTRAINT "mood_logs_mood_range" CHECK ("mood" BETWEEN 1 AND 5);

-- 3. Row Level Security on every table.
--    With RLS on and no policies, the Supabase public API (anon / authenticated keys)
--    cannot read or write these tables. The backend connects with the database owner
--    role through Prisma, which is not blocked by RLS. This protects health data.
ALTER TABLE "profiles"      ENABLE ROW LEVEL SECURITY;
ALTER TABLE "water_logs"    ENABLE ROW LEVEL SECURITY;
ALTER TABLE "exercise_logs" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "sleep_logs"    ENABLE ROW LEVEL SECURITY;
ALTER TABLE "mood_logs"     ENABLE ROW LEVEL SECURITY;
ALTER TABLE "weight_logs"   ENABLE ROW LEVEL SECURITY;
ALTER TABLE "goals"         ENABLE ROW LEVEL SECURITY;
ALTER TABLE "streaks"       ENABLE ROW LEVEL SECURITY;
ALTER TABLE "reminders"     ENABLE ROW LEVEL SECURITY;
ALTER TABLE "devices"       ENABLE ROW LEVEL SECURITY;
ALTER TABLE "insights"      ENABLE ROW LEVEL SECURITY;
