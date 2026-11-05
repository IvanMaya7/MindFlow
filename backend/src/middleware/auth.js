const jwt = require('jsonwebtoken');
const { jwtSecret } = require('../config/env');

function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const [scheme, token] = header.split(' ');

  if (scheme !== 'Bearer' || !token) {
    return res.status(401).json({ error: 'Token requerido' });
  }

  try {
    const payload = jwt.verify(token, jwtSecret);
    req.user = { id: payload.sub };
    next();
  } catch {
    return res.status(401).json({ error: 'Token inválido o expirado' });
  }
}

module.exports = { requireAuth };
