-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateEnum
CREATE TYPE "Units" AS ENUM ('metric', 'imperial');

-- CreateEnum
CREATE TYPE "UserRole" AS ENUM ('user', 'admin');

-- CreateEnum
CREATE TYPE "PlanType" AS ENUM ('free', 'premium');

-- CreateEnum
CREATE TYPE "LogSource" AS ENUM ('manual', 'imported');

-- CreateEnum
CREATE TYPE "Intensity" AS ENUM ('low', 'medium', 'high');

-- CreateEnum
CREATE TYPE "GoalMetric" AS ENUM ('water', 'exercise', 'sleep');

-- CreateEnum
CREATE TYPE "ReminderType" AS ENUM ('water', 'bedtime', 'checkin');

-- CreateEnum
CREATE TYPE "DevicePlatform" AS ENUM ('ios', 'android');

-- CreateTable
CREATE TABLE "profiles" (
    "id" UUID NOT NULL,
    "name" TEXT,
    "birth_year" INTEGER,
    "height_cm" DECIMAL(5,1),
    "target_weight_kg" DECIMAL(5,2),
    "units" "Units" NOT NULL DEFAULT 'metric',
    "timezone" TEXT NOT NULL DEFAULT 'UTC',
    "avatar_url" TEXT,
    "role" "UserRole" NOT NULL DEFAULT 'user',
    "plan" "PlanType" NOT NULL DEFAULT 'free',
    "onboarding_completed" BOOLEAN NOT NULL DEFAULT false,
    "is_disabled" BOOLEAN NOT NULL DEFAULT false,
    "deleted_at" TIMESTAMPTZ,
    "stripe_customer_id" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "profiles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "water_logs" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "amount_ml" INTEGER NOT NULL,
    "logged_at" TIMESTAMPTZ NOT NULL,
    "source" "LogSource" NOT NULL DEFAULT 'manual',
    "external_id" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "water_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "exercise_logs" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "activity_type" TEXT NOT NULL,
    "duration_min" INTEGER NOT NULL,
    "intensity" "Intensity" NOT NULL,
    "calories" INTEGER,
    "notes" TEXT,
    "logged_at" TIMESTAMPTZ NOT NULL,
    "source" "LogSource" NOT NULL DEFAULT 'manual',
    "external_id" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "exercise_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sleep_logs" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "bed_time" TIMESTAMPTZ NOT NULL,
    "wake_time" TIMESTAMPTZ NOT NULL,
    "duration_min" INTEGER NOT NULL,
    "quality" SMALLINT NOT NULL,
    "date" DATE NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "sleep_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "mood_logs" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "mood" SMALLINT NOT NULL,
    "tags" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "note" TEXT,
    "logged_at" TIMESTAMPTZ NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "mood_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "weight_logs" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "weight_kg" DECIMAL(5,2) NOT NULL,
    "bmi" DECIMAL(4,1),
    "logged_at" TIMESTAMPTZ NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "weight_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "goals" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "metric" "GoalMetric" NOT NULL,
    "target_value" DECIMAL(65,30) NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "goals_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "streaks" (
    "goal_id" UUID NOT NULL,
    "current" INTEGER NOT NULL DEFAULT 0,
    "best" INTEGER NOT NULL DEFAULT 0,
    "last_met_date" DATE,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "streaks_pkey" PRIMARY KEY ("goal_id")
);

-- CreateTable
CREATE TABLE "reminders" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "type" "ReminderType" NOT NULL,
    "time_of_day" TIME,
    "interval_min" INTEGER,
    "enabled" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "reminders_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "devices" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "push_token" TEXT NOT NULL,
    "platform" "DevicePlatform" NOT NULL,
    "last_seen_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "devices_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "insights" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "week_start" DATE NOT NULL,
    "summary" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "insights_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "water_logs_user_id_logged_at_idx" ON "water_logs"("user_id", "logged_at");

-- CreateIndex
CREATE UNIQUE INDEX "water_logs_user_id_source_external_id_key" ON "water_logs"("user_id", "source", "external_id");

-- CreateIndex
CREATE INDEX "exercise_logs_user_id_logged_at_idx" ON "exercise_logs"("user_id", "logged_at");

-- CreateIndex
CREATE UNIQUE INDEX "exercise_logs_user_id_source_external_id_key" ON "exercise_logs"("user_id", "source", "external_id");

-- CreateIndex
CREATE INDEX "sleep_logs_user_id_date_idx" ON "sleep_logs"("user_id", "date");

-- CreateIndex
CREATE INDEX "mood_logs_user_id_logged_at_idx" ON "mood_logs"("user_id", "logged_at");

-- CreateIndex
CREATE INDEX "weight_logs_user_id_logged_at_idx" ON "weight_logs"("user_id", "logged_at");

-- CreateIndex
CREATE UNIQUE INDEX "goals_user_id_metric_key" ON "goals"("user_id", "metric");

-- CreateIndex
CREATE UNIQUE INDEX "reminders_user_id_type_key" ON "reminders"("user_id", "type");

-- CreateIndex
CREATE UNIQUE INDEX "devices_push_token_key" ON "devices"("push_token");

-- CreateIndex
CREATE UNIQUE INDEX "insights_user_id_week_start_key" ON "insights"("user_id", "week_start");

-- AddForeignKey
ALTER TABLE "water_logs" ADD CONSTRAINT "water_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "profiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "exercise_logs" ADD CONSTRAINT "exercise_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "profiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sleep_logs" ADD CONSTRAINT "sleep_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "profiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mood_logs" ADD CONSTRAINT "mood_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "profiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "weight_logs" ADD CONSTRAINT "weight_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "profiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "goals" ADD CONSTRAINT "goals_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "profiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "streaks" ADD CONSTRAINT "streaks_goal_id_fkey" FOREIGN KEY ("goal_id") REFERENCES "goals"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reminders" ADD CONSTRAINT "reminders_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "profiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "devices" ADD CONSTRAINT "devices_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "profiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "insights" ADD CONSTRAINT "insights_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "profiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

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

-- Review fixes
-- mood_logs.tags must never be NULL (Prisma cannot express NOT NULL on arrays)
ALTER TABLE "mood_logs" ALTER COLUMN "tags" SET NOT NULL;

-- More value checks
ALTER TABLE "weight_logs" ADD CONSTRAINT "weight_logs_weight_kg_positive" CHECK ("weight_kg" > 0);
ALTER TABLE "goals" ADD CONSTRAINT "goals_target_value_positive" CHECK ("target_value" > 0);
ALTER TABLE "reminders" ADD CONSTRAINT "reminders_interval_min_positive" CHECK ("interval_min" IS NULL OR "interval_min" > 0);
ALTER TABLE "profiles" ADD CONSTRAINT "profiles_height_cm_range" CHECK ("height_cm" IS NULL OR "height_cm" BETWEEN 50 AND 272);
ALTER TABLE "profiles" ADD CONSTRAINT "profiles_target_weight_kg_positive" CHECK ("target_weight_kg" IS NULL OR "target_weight_kg" > 0);