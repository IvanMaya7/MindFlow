const { ZodError } = require('zod');

function notFound(req, res) {
  res.status(404).json({ error: 'Ruta no encontrada' });
}

// eslint-disable-next-line no-unused-vars
function errorHandler(err, req, res, next) {
  if (err instanceof ZodError) {
    return res.status(400).json({
      error: 'Datos inválidos',
      details: err.errors.map((e) => ({ field: e.path.join('.'), message: e.message })),
    });
  }

  if (err.code === '23505') {
    return res.status(409).json({ error: 'El registro ya existe' });
  }

  console.error(err);
  res.status(500).json({ error: 'Error interno del servidor' });
}

module.exports = { notFound, errorHandler };
