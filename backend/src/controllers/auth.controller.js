const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { z } = require('zod');
const db = require('../db/pool');
const { jwtSecret, jwtExpiresIn } = require('../config/env');

const registerSchema = z.object({
  email: z.string().email().toLowerCase(),
  password: z.string().min(8, 'Mínimo 8 caracteres'),
  displayName: z.string().min(1).max(80),
});

const loginSchema = z.object({
  email: z.string().email().toLowerCase(),
  password: z.string().min(1),
});

const preferencesSchema = z.object({
  allowAiAnalysis: z.boolean().optional(),
  theme: z.enum(['light', 'dark', 'system']).optional(),
  displayName: z.string().min(1).max(80).optional(),
});

const signToken = (userId) =>
  jwt.sign({ sub: userId }, jwtSecret, { expiresIn: jwtExpiresIn });

const publicUser = (row) => ({
  id: row.id,
  email: row.email,
  displayName: row.display_name,
  allowAiAnalysis: row.allow_ai_analysis,
  theme: row.theme,
  createdAt: row.created_at,
});

async function register(req, res, next) {
  try {
    const { email, password, displayName } = registerSchema.parse(req.body);
    const hash = await bcrypt.hash(password, 12);

    const { rows } = await db.query(
      `INSERT INTO users (email, password_hash, display_name)
       VALUES ($1, $2, $3) RETURNING *`,
      [email, hash, displayName]
    );

    res.status(201).json({ token: signToken(rows[0].id), user: publicUser(rows[0]) });
  } catch (err) {
    next(err);
  }
}

async function login(req, res, next) {
  try {
    const { email, password } = loginSchema.parse(req.body);
    const { rows } = await db.query('SELECT * FROM users WHERE email = $1', [email]);
    const user = rows[0];

    const ok = user && (await bcrypt.compare(password, user.password_hash));
    if (!ok) return res.status(401).json({ error: 'Credenciales incorrectas' });

    res.json({ token: signToken(user.id), user: publicUser(user) });
  } catch (err) {
    next(err);
  }
}

async function me(req, res, next) {
  try {
    const { rows } = await db.query('SELECT * FROM users WHERE id = $1', [req.user.id]);
    if (!rows[0]) return res.status(404).json({ error: 'Usuario no encontrado' });
    res.json(publicUser(rows[0]));
  } catch (err) {
    next(err);
  }
}

async function updatePreferences(req, res, next) {
  try {
    const data = preferencesSchema.parse(req.body);
    const { rows } = await db.query(
      `UPDATE users SET
         allow_ai_analysis = COALESCE($2, allow_ai_analysis),
         theme             = COALESCE($3, theme),
         display_name      = COALESCE($4, display_name)
       WHERE id = $1 RETURNING *`,
      [req.user.id, data.allowAiAnalysis ?? null, data.theme ?? null, data.displayName ?? null]
    );
    res.json(publicUser(rows[0]));
  } catch (err) {
    next(err);
  }
}

module.exports = { register, login, me, updatePreferences };
