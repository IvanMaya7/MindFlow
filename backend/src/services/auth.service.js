const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const prisma = require('../lib/prisma');
const AppError = require('../utils/AppError');
const { jwtSecret, jwtExpiresIn } = require('../config/config');
const { sendPasswordResetCode } = require('./mail.service');

const SALT_ROUNDS = 12;

// Recuperación de contraseña
const RESET_TTL_MIN = 15;
const MAX_ATTEMPTS = 5;
const RESEND_WAIT_MS = 60 * 1000;

// Guardamos solo un hash del código, nunca el código en claro
function hashCode(email, code) {
  return crypto
    .createHmac('sha256', jwtSecret)
    .update(`${email}:${code}`)
    .digest('hex');
}

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

const register = async ({ email, password, phone, displayName, allowAiAnalysis, emergencyContact }) => {
  const normalizedEmail = email.toLowerCase().trim();

  const existing = await prisma.user.findUnique({ where: { email: normalizedEmail } });
  if (existing) throw new AppError('Ya existe una cuenta con ese correo', 409);

  const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);

  const user = await prisma.user.create({
    data: {
      email: normalizedEmail,
      passwordHash,
      displayName: displayName.trim(),
      phone: phone.trim(),
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

const emailExists = async (email) => {
  const user = await prisma.user.findUnique({
    where: { email: email.toLowerCase().trim() },
    select: { id: true },
  });
  return Boolean(user);
};

// Paso 1 de la recuperación: genera el código y lo manda por correo.
// Nunca revela si el correo existe: si no existe, simplemente no hace nada.
const requestPasswordReset = async (email) => {
  const normalizedEmail = email.toLowerCase().trim();

  const user = await prisma.user.findUnique({
    where: { email: normalizedEmail },
    select: { id: true },
  });
  if (!user) return;

  // Evita spam: un código por minuto como máximo
  const last = await prisma.passwordReset.findFirst({
    where: { email: normalizedEmail },
    orderBy: { createdAt: 'desc' },
  });
  if (last && Date.now() - last.createdAt.getTime() < RESEND_WAIT_MS) return;

  const code = String(crypto.randomInt(0, 1000000)).padStart(6, '0');

  await prisma.passwordReset.deleteMany({ where: { email: normalizedEmail } });
  await prisma.passwordReset.create({
    data: {
      email: normalizedEmail,
      codeHash: hashCode(normalizedEmail, code),
      expiresAt: new Date(Date.now() + RESET_TTL_MIN * 60 * 1000),
    },
  });

  // Sin await: la respuesta tarda igual exista o no el correo
  sendPasswordResetCode(normalizedEmail, code).catch((e) =>
    console.error('No se pudo enviar el correo:', e.message)
  );
};

// Paso 2: valida el código y guarda la contraseña nueva.
const resetPassword = async ({ email, code, newPassword }) => {
  const normalizedEmail = email.toLowerCase().trim();
  const invalid = () => new AppError('Código inválido o vencido', 400);

  const record = await prisma.passwordReset.findFirst({
    where: { email: normalizedEmail, usedAt: null, expiresAt: { gt: new Date() } },
    orderBy: { createdAt: 'desc' },
  });
  if (!record || record.attempts >= MAX_ATTEMPTS) throw invalid();

  const expected = Buffer.from(record.codeHash, 'hex');
  const given = Buffer.from(hashCode(normalizedEmail, code), 'hex');
  if (!crypto.timingSafeEqual(expected, given)) {
    await prisma.passwordReset.update({
      where: { id: record.id },
      data: { attempts: { increment: 1 } },
    });
    throw invalid();
  }

  const passwordHash = await bcrypt.hash(newPassword, SALT_ROUNDS);
  await prisma.$transaction([
    prisma.user.update({ where: { email: normalizedEmail }, data: { passwordHash } }),
    prisma.passwordReset.deleteMany({ where: { email: normalizedEmail } }),
  ]);
};

module.exports = {
  register,
  login,
  getProfile,
  emailExists,
  requestPasswordReset,
  resetPassword,
};