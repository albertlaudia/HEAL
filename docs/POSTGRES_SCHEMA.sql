-- HEAL — Postgres schema
-- Generated 2026-07-14 from PocketBase introspection.
-- 11 tables, all read paths are public, writes are superuser-only.
-- Run: psql -U heal -d heal -f POSTGRES_SCHEMA.sql

BEGIN;

-- ── heal_meditations (271 records) ──────────────────────────────
CREATE TABLE IF NOT EXISTS heal_meditations (
  id                TEXT PRIMARY KEY,
  title             TEXT NOT NULL,
  slug              TEXT NOT NULL UNIQUE,
  scripture_ref     TEXT,
  scripture_text    TEXT,
  translation       TEXT,
  body              TEXT NOT NULL,
  reflection        TEXT,
  prayer            TEXT,
  audio_url         TEXT,
  illustration_url  TEXT,
  duration_seconds  INT,
  theme             TEXT,
  season            TEXT,
  day_of_year       INT,
  launch_batch      TEXT,
  sort_order        INT,
  is_published      BOOLEAN DEFAULT false,
  tags              JSONB DEFAULT '[]'::jsonb,
  is_sleep_story    BOOLEAN DEFAULT false,
  created_at        TIMESTAMPTZ DEFAULT now(),
  updated_at        TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_heal_meditations_slug     ON heal_meditations(slug);
CREATE INDEX IF NOT EXISTS idx_heal_meditations_published ON heal_meditations(is_published) WHERE is_published = true;
CREATE INDEX IF NOT EXISTS idx_heal_meditations_day       ON heal_meditations(day_of_year);
CREATE INDEX IF NOT EXISTS idx_heal_meditations_theme     ON heal_meditations(theme);
CREATE INDEX IF NOT EXISTS idx_heal_meditations_search    ON heal_meditations USING gin(to_tsvector('english', coalesce(title,'') || ' ' || coalesce(body,'') || ' ' || coalesce(reflection,'')));

-- ── heal_praise (124 records) ──────────────────────────────────
CREATE TABLE IF NOT EXISTS heal_praise (
  id                TEXT PRIMARY KEY,
  title             TEXT NOT NULL,
  slug              TEXT NOT NULL UNIQUE,
  subtitle          TEXT,
  lyrics            TEXT,
  chords            TEXT,
  scripture_refs    JSONB DEFAULT '[]'::jsonb,
  reflection        TEXT,
  category          TEXT,
  key_signature     TEXT,
  tempo_bpm         INT,
  meter             TEXT,
  audio_url         TEXT,
  illustration_url  TEXT,
  day_of_year       INT,
  sort_order        INT,
  is_published      BOOLEAN DEFAULT false,
  description       TEXT,
  tags              JSONB DEFAULT '[]'::jsonb,
  emotion           TEXT,
  mood              TEXT,
  voice             TEXT,
  best_for          JSONB DEFAULT '[]'::jsonb,
  duration_seconds  INT,
  audio_license     TEXT,
  audio_source      TEXT,
  review            TEXT,
  respect           TEXT,
  learning          TEXT,
  created_at        TIMESTAMPTZ DEFAULT now(),
  updated_at        TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_heal_praise_slug       ON heal_praise(slug);
CREATE INDEX IF NOT EXISTS idx_heal_praise_published  ON heal_praise(is_published) WHERE is_published = true;
CREATE INDEX IF NOT EXISTS idx_heal_praise_day        ON heal_praise(day_of_year);
CREATE INDEX IF NOT EXISTS idx_heal_praise_category   ON heal_praise(category);

-- ── heal_prayers (67 records) ──────────────────────────────────
CREATE TABLE IF NOT EXISTS heal_prayers (
  id                TEXT PRIMARY KEY,
  title             TEXT NOT NULL,
  slug              TEXT NOT NULL UNIQUE,
  body              TEXT NOT NULL,
  category          TEXT,
  attribution       TEXT,
  illustration_url  TEXT,
  sort_order        INT,
  is_published      BOOLEAN DEFAULT false,
  emotion           TEXT,
  tags              JSONB DEFAULT '[]'::jsonb,
  cycle_position    INT,
  cycle_year        INT,
  is_event_prayer   BOOLEAN DEFAULT false,
  source_event      TEXT,
  event_date        DATE,
  created_at        TIMESTAMPTZ DEFAULT now(),
  updated_at        TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_heal_prayers_slug      ON heal_prayers(slug);
CREATE INDEX IF NOT EXISTS idx_heal_prayers_published ON heal_prayers(is_published) WHERE is_published = true;
CREATE INDEX IF NOT EXISTS idx_heal_prayers_cycle     ON heal_prayers(cycle_year, cycle_position);

-- ── heal_scriptures (31 records) ──────────────────────────────
CREATE TABLE IF NOT EXISTS heal_scriptures (
  id                  TEXT PRIMARY KEY,
  reference           TEXT NOT NULL,
  text                TEXT NOT NULL,
  translation         TEXT,
  theme               TEXT,
  reflection_prompt   TEXT,
  day_of_year         INT,
  is_published        BOOLEAN DEFAULT false,
  slug                TEXT UNIQUE,
  tags                JSONB DEFAULT '[]'::jsonb,
  cycle_position      INT,
  cycle_year          INT,
  emotion             TEXT,
  created_at          TIMESTAMPTZ DEFAULT now(),
  updated_at          TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_heal_scriptures_slug      ON heal_scriptures(slug);
CREATE INDEX IF NOT EXISTS idx_heal_scriptures_published ON heal_scriptures(is_published) WHERE is_published = true;
CREATE INDEX IF NOT EXISTS idx_heal_scriptures_day       ON heal_scriptures(day_of_year);

-- ── heal_quotes (60 records) ──────────────────────────────────
CREATE TABLE IF NOT EXISTS heal_quotes (
  id                TEXT PRIMARY KEY,
  text              TEXT NOT NULL,
  attribution       TEXT,
  source            TEXT,
  category          TEXT,
  illustration_url  TEXT,
  day_of_year       INT,
  is_motivation     BOOLEAN DEFAULT false,
  is_published      BOOLEAN DEFAULT false,
  slug              TEXT UNIQUE,
  tags              JSONB DEFAULT '[]'::jsonb,
  cycle_position    INT,
  cycle_year        INT,
  emotion           TEXT,
  created_at        TIMESTAMPTZ DEFAULT now(),
  updated_at        TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_heal_quotes_slug      ON heal_quotes(slug);
CREATE INDEX IF NOT EXISTS idx_heal_quotes_published ON heal_quotes(is_published) WHERE is_published = true;
CREATE INDEX IF NOT EXISTS idx_heal_quotes_day       ON heal_quotes(day_of_year);

-- ── heal_breathwork (6 records) ──────────────────────────────
CREATE TABLE IF NOT EXISTS heal_breathwork (
  id                TEXT PRIMARY KEY,
  name              TEXT NOT NULL,
  slug              TEXT NOT NULL UNIQUE,
  description       TEXT,
  instructions      TEXT,
  pattern           TEXT,
  inhale_seconds    INT,
  hold_seconds      INT,
  exhale_seconds    INT,
  cycles            INT,
  illustration_url  TEXT,
  audio_url         TEXT,
  theme             TEXT,
  created_at        TIMESTAMPTZ DEFAULT now(),
  updated_at        TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_heal_breathwork_slug ON heal_breathwork(slug);

-- ── heal_essays (3 records) ──────────────────────────────────
CREATE TABLE IF NOT EXISTS heal_essays (
  id                TEXT PRIMARY KEY,
  title             TEXT NOT NULL,
  slug              TEXT NOT NULL UNIQUE,
  subtitle          TEXT,
  body              TEXT NOT NULL,
  illustration_url  TEXT,
  category          TEXT,
  reading_minutes   INT,
  day_of_year       INT,
  is_published      BOOLEAN DEFAULT false,
  tags              JSONB DEFAULT '[]'::jsonb,
  cycle_position    INT,
  cycle_year        INT,
  created_at        TIMESTAMPTZ DEFAULT now(),
  updated_at        TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_heal_essays_slug      ON heal_essays(slug);
CREATE INDEX IF NOT EXISTS idx_heal_essays_published ON heal_essays(is_published) WHERE is_published = true;
CREATE INDEX IF NOT EXISTS idx_heal_essays_day       ON heal_essays(day_of_year);

-- ── heal_bible_readings (365 records) ──────────────────────
CREATE TABLE IF NOT EXISTS heal_bible_readings (
  id                TEXT PRIMARY KEY,
  day_number        INT NOT NULL UNIQUE,
  book              TEXT,
  chapter           INT,
  verse_start       INT,
  verse_end         INT,
  reference         TEXT NOT NULL,
  title             TEXT,
  summary           TEXT,
  reflection        TEXT,
  is_published      BOOLEAN DEFAULT true,
  cycle_year        INT,
  cycle_position    INT,
  created_at        TIMESTAMPTZ DEFAULT now(),
  updated_at        TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_heal_bible_readings_day  ON heal_bible_readings(day_number);
CREATE INDEX IF NOT EXISTS idx_heal_bible_readings_book ON heal_bible_readings(book);

-- ── heal_bible_progress (0 records — auth-gated writes only) ─
CREATE TABLE IF NOT EXISTS heal_bible_progress (
  id                  TEXT PRIMARY KEY,
  user_id             TEXT NOT NULL,  -- FK to auth.users.id once auth lands; nullable for now
  day_number          INT NOT NULL,
  completed_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  notes               TEXT,
  reading_seconds     INT DEFAULT 0,
  created_at          TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_heal_bible_progress_user ON heal_bible_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_heal_bible_progress_day  ON heal_bible_progress(day_number);
CREATE UNIQUE INDEX IF NOT EXISTS uq_heal_bible_progress_user_day
  ON heal_bible_progress(user_id, day_number);

-- ── heal_world (13 records) ──────────────────────────────
CREATE TABLE IF NOT EXISTS heal_world (
  id                TEXT PRIMARY KEY,
  title             TEXT NOT NULL,
  slug              TEXT NOT NULL UNIQUE,
  subtitle          TEXT,
  body              TEXT NOT NULL,
  scripture_ref     TEXT,
  prayer            TEXT,
  expectation       TEXT,
  illustration_url  TEXT,
  continent         TEXT,
  country_code      TEXT,
  country_name      TEXT,
  is_event          BOOLEAN DEFAULT false,
  event_date        DATE,
  category          TEXT,  -- 'challenge' | 'grace' | 'gratitude' | etc.
  is_published      BOOLEAN DEFAULT true,
  day_of_year       INT,
  cycle_year        INT,
  cycle_position    INT,
  created_at        TIMESTAMPTZ DEFAULT now(),
  updated_at        TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_heal_world_slug      ON heal_world(slug);
CREATE INDEX IF NOT EXISTS idx_heal_world_published ON heal_world(is_published) WHERE is_published = true;
CREATE INDEX IF NOT EXISTS idx_heal_world_day       ON heal_world(day_of_year);
CREATE INDEX IF NOT EXISTS idx_heal_world_category  ON heal_world(category);

-- ── heal_pages (0 records — placeholder for static content) ─────
CREATE TABLE IF NOT EXISTS heal_pages (
  id                TEXT PRIMARY KEY,
  slug              TEXT NOT NULL UNIQUE,
  title             TEXT NOT NULL,
  body              TEXT NOT NULL,
  meta_description  TEXT,
  is_published      BOOLEAN DEFAULT false,
  created_at        TIMESTAMPTZ DEFAULT now(),
  updated_at        TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_heal_pages_slug ON heal_pages(slug);

-- ── Sticker / progress (PB keeps these for now) ────────────
-- heal_stickers, heal_sticker_unlocks, heal_user_progress,
-- heal_favorites, heal_downloaded all stay in PocketBase until
-- Firebase Auth lands. See POSTGRES_MIGRATION_PLAN.md.

COMMIT;

-- Verification
SELECT 'Tables created:' AS info, count(*) AS n
FROM information_schema.tables
WHERE table_schema = 'public' AND table_name LIKE 'heal_%';
