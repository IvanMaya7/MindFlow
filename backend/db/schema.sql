-- MindFlow: esquema PostgreSQL (adaptado del modelo Firestore del documento)
-- Uso: psql -U postgres -d mindflow -f db/schema.sql

CREATE EXTENSION IF NOT EXISTS pgcrypto; -- gen_random_uuid()

-- ---------- users ----------
CREATE TABLE IF NOT EXISTS users (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email             TEXT NOT NULL UNIQUE,
  password_hash     TEXT NOT NULL,
  display_name      TEXT NOT NULL,
  allow_ai_analysis BOOLEAN NOT NULL DEFAULT FALSE,   -- consentimiento explícito
  theme             TEXT NOT NULL DEFAULT 'system'
                    CHECK (theme IN ('light', 'dark', 'system')),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------- emergency_contacts (Red de Apoyo) ----------
CREATE TABLE IF NOT EXISTS emergency_contacts (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name       TEXT NOT NULL,
  phone      TEXT,
  email      TEXT,
  relation   TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (phone IS NOT NULL OR email IS NOT NULL)
);
CREATE INDEX IF NOT EXISTS idx_contacts_user ON emergency_contacts(user_id);

-- ---------- journal_entries (Diario Emocional) ----------
CREATE TABLE IF NOT EXISTS journal_entries (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  entry_date         TIMESTAMPTZ NOT NULL DEFAULT now(),
  primary_emotion    TEXT NOT NULL,
  emotion_intensity  SMALLINT CHECK (emotion_intensity BETWEEN 0 AND 10),
  energy_level       SMALLINT CHECK (energy_level BETWEEN 0 AND 10),
  stress_level       SMALLINT CHECK (stress_level BETWEEN 0 AND 10),
  sleep_quality      SMALLINT CHECK (sleep_quality BETWEEN 0 AND 10),
  text_notes         TEXT,
  tags               TEXT[] NOT NULL DEFAULT '{}',
  -- Resultado del análisis de IA (se llena después, de forma asíncrona)
  sentiment_score    REAL CHECK (sentiment_score BETWEEN -1.0 AND 1.0),
  risk_level         TEXT CHECK (risk_level IN ('low', 'medium', 'high', 'critical')),
  extracted_keywords TEXT[] NOT NULL DEFAULT '{}',
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_journal_user_date ON journal_entries(user_id, entry_date DESC);

-- ---------- ai_insights ----------
CREATE TABLE IF NOT EXISTS ai_insights (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  period_start TIMESTAMPTZ NOT NULL,
  period_end   TIMESTAMPTZ NOT NULL,
  insight_text TEXT NOT NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_insights_user ON ai_insights(user_id, period_end DESC);

-- ---------- resources (Psicoeducación) ----------
CREATE TABLE IF NOT EXISTS resources (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title      TEXT NOT NULL,
  content    TEXT NOT NULL,            -- Markdown
  category   TEXT NOT NULL,            -- ej. 'Ansiedad', 'Respiración'
  image_url  TEXT,
  is_premium BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_resources_category ON resources(category);

-- ---------- datos semilla ----------
INSERT INTO resources (title, content, category)
SELECT 'Respiración 4-7-8',
       E'Inhala por la nariz 4 segundos, sostén 7 y exhala por la boca 8. Repite 4 veces.',
       'Respiración'
WHERE NOT EXISTS (SELECT 1 FROM resources WHERE title = 'Respiración 4-7-8');
