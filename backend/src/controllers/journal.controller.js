const { z } = require('zod');
const db = require('../db/pool');

const level = z.number().int().min(0).max(10);

const entrySchema = z.object({
  date: z.string().datetime().optional(),
  primaryEmotion: z.string().min(1).max(40),
  emotionIntensity: level.optional(),
  energyLevel: level.optional(),
  stressLevel: level.optional(),
  sleepQuality: level.optional(),
  textNotes: z.string().max(10000).optional(),
  tags: z.array(z.string().max(30)).max(20).default([]),
});

const toApi = (r) => ({
  id: r.id,
  date: r.entry_date,
  primaryEmotion: r.primary_emotion,
  emotionIntensity: r.emotion_intensity,
  metrics: {
    energyLevel: r.energy_level,
    stressLevel: r.stress_level,
    sleepQuality: r.sleep_quality,
  },
  textNotes: r.text_notes,
  tags: r.tags,
  aiAnalysis: {
    sentimentScore: r.sentiment_score,
    riskLevel: r.risk_level,
    extractedKeywords: r.extracted_keywords,
  },
});

async function create(req, res, next) {
  try {
    const d = entrySchema.parse(req.body);
    const { rows } = await db.query(
      `INSERT INTO journal_entries
         (user_id, entry_date, primary_emotion, emotion_intensity,
          energy_level, stress_level, sleep_quality, text_notes, tags)
       VALUES ($1, COALESCE($2, now()), $3, $4, $5, $6, $7, $8, $9)
       RETURNING *`,
      [
        req.user.id,
        d.date ?? null,
        d.primaryEmotion,
        d.emotionIntensity ?? null,
        d.energyLevel ?? null,
        d.stressLevel ?? null,
        d.sleepQuality ?? null,
        d.textNotes ?? null,
        d.tags,
      ]
    );

    // TODO (fase IA): si el usuario dio consentimiento (users.allow_ai_analysis),
    // encolar el análisis de esta entrada de forma asíncrona.
    res.status(201).json(toApi(rows[0]));
  } catch (err) {
    next(err);
  }
}

async function list(req, res, next) {
  try {
    const limit = Math.min(Number(req.query.limit) || 30, 100);
    const offset = Number(req.query.offset) || 0;
    const { rows } = await db.query(
      `SELECT * FROM journal_entries
       WHERE user_id = $1
         AND ($2::timestamptz IS NULL OR entry_date >= $2)
         AND ($3::timestamptz IS NULL OR entry_date <= $3)
       ORDER BY entry_date DESC
       LIMIT $4 OFFSET $5`,
      [req.user.id, req.query.from ?? null, req.query.to ?? null, limit, offset]
    );
    res.json(rows.map(toApi));
  } catch (err) {
    next(err);
  }
}

async function getOne(req, res, next) {
  try {
    const { rows } = await db.query(
      'SELECT * FROM journal_entries WHERE id = $1 AND user_id = $2',
      [req.params.id, req.user.id]
    );
    if (!rows[0]) return res.status(404).json({ error: 'Entrada no encontrada' });
    res.json(toApi(rows[0]));
  } catch (err) {
    next(err);
  }
}

async function remove(req, res, next) {
  try {
    const { rowCount } = await db.query(
      'DELETE FROM journal_entries WHERE id = $1 AND user_id = $2',
      [req.params.id, req.user.id]
    );
    if (!rowCount) return res.status(404).json({ error: 'Entrada no encontrada' });
    res.status(204).end();
  } catch (err) {
    next(err);
  }
}

// Promedios diarios para las gráficas del dashboard
async function stats(req, res, next) {
  try {
    const days = Math.min(Number(req.query.days) || 30, 365);
    const { rows } = await db.query(
      `SELECT date_trunc('day', entry_date) AS day,
              round(avg(stress_level)::numeric, 1)  AS stress,
              round(avg(energy_level)::numeric, 1)  AS energy,
              round(avg(sleep_quality)::numeric, 1) AS sleep
       FROM journal_entries
       WHERE user_id = $1 AND entry_date >= now() - ($2 || ' days')::interval
       GROUP BY 1 ORDER BY 1`,
      [req.user.id, String(days)]
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

module.exports = { create, list, getOne, remove, stats };
