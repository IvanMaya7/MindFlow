const db = require('../db/pool');

async function list(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT id, title, content, category, image_url AS "imageUrl", is_premium AS "isPremium"
       FROM resources
       WHERE ($1::text IS NULL OR category = $1)
       ORDER BY created_at DESC`,
      [req.query.category ?? null]
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

module.exports = { list };
