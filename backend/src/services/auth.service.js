const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const prisma = require('../lib/prisma');
const AppError = require('../utils/AppError');
const { jwtSecret, jwtExpiresIn } = require('../config/env');

const SALT_ROUNDS = 12;

const sanitizeUser = (user) => ({
  id: user.id,
  email: user.email,
  displayName: user.displayName,
  allowAiAnalysis: user.allowAiAnalysis,
  theme: user.theme,
  createdAt: user.createdAt,
});

const signToken = (userId) =>
  jwt.sign({ sub: userId }, jwtSecret, { expiresIn: jwtExpiresIn });

const register = async ({ email, password, displayName, allowAiAnalysis, emergencyContact }) => {
  const normalizedEmail = email.toLowerCase().trim();

  const existing = await prisma.user.findUnique({ where: { email: normalizedEmail } });
  if (existing) throw new AppError('Ya existe una cuenta con ese correo', 409);

  const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);

  const user = await prisma.user.create({
    data: {
      email: normalizedEmail,
      passwordHash,
      displayName: displayName.trim(),
      allowAiAnalysis,
      emergencyContacts: {
        create: {
          name: emergencyContact.name.trim(),
          phone: emergencyContact.phone.trim(),
          relation: emergencyContact.relation,
        },
      },
    },
  });

  return { user: sanitizeUser(user), token: signToken(user.id) };
};

const login = async ({ email, password }) => {
  const user = await prisma.user.findUnique({ where: { email: email.toLowerCase().trim() } });

  // Mismo mensaje para correo o contraseña incorrectos (no revela qué falló)
  const valid = user && (await bcrypt.compare(password, user.passwordHash));
  if (!valid) throw new AppError('Correo o contraseña incorrectos', 401);

  return { user: sanitizeUser(user), token: signToken(user.id) };
};

const getProfile = async (userId) => {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) throw new AppError('Usuario no encontrado', 404);
  return sanitizeUser(user);
};

module.exports = { register, login, getProfile };
