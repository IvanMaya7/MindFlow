require('dotenv').config();

const required = ['DATABASE_URL', 'JWT_SECRET'];
required.forEach((key) => {
  if (!process.env[key]) throw new Error(`Falta la variable de entorno ${key}`);
});

module.exports = {
  port: process.env.PORT || 4001,
  jwtSecret: process.env.JWT_SECRET,
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
};
