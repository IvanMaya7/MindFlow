const prisma = require("../lib/prisma");

// Contactos de confianza del usuario (los que capturó al registrarse)
async function listContacts(userId) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { emergencyContacts: { select: { name: true, phone: true, relation: true } } },
  });
  return user?.emergencyContacts ?? [];
}

module.exports = { listContacts };