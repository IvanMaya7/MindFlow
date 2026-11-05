const { z } = require('zod');
const db = require('../db/pool');

const contactSchema = z
  .object({
    name: z.string().min(1).max(80),
    phone: z.string().min(7).max(20).optional(),
    email: z.string().email().optional(),
    relation: z.string().max(40).optional(),
  })
  .refine((c) => c.phone || c.email, { message: 'Se requiere teléfono o correo' });

const toApi = (r) => ({
  id: r.id,
  name: r.name,
  phone: r.phone,
  email: r.email,
  relation: r.relation,
});

async function list(req, res, next) {
  try {
    const { rows } = await db.query(
      'SELECT * FROM emergency_contacts WHERE user_id = $1 ORDER BY created_at',
      [req.user.id]
    );
    res.json(rows.map(toApi));
  } catch (err) {
    next(err);
  }
}

async function create(req, res, next) {
  try {
    const c = contactSchema.parse(req.body);
    const { rows } = await db.query(
      `INSERT INTO emergency_contacts (user_id, name, phone, email, relation)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [req.user.id, c.name, c.phone ?? null, c.email ?? null, c.relation ?? null]
    );
    res.status(201).json(toApi(rows[0]));
  } catch (err) {
    next(err);
  }
}

async function remove(req, res, next) {
  try {
    const { rowCount } = await db.query(
      'DELETE FROM emergency_contacts WHERE id = $1 AND user_id = $2',
      [req.params.id, req.user.id]
    );
    if (!rowCount) return res.status(404).json({ error: 'Contacto no encontrado' });
    res.status(204).end();
  } catch (err) {
    next(err);
  }
}

module.exports = { list, create, remove };
