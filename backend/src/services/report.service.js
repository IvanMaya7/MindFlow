const crypto = require("crypto");
const prisma = require("../lib/prisma");

const TTL_MIN = 15;
const DAY_MS = 86400000;

const EMOTIONS = {
  calma: "Calma", esperanzado: "Esperanzado", cansado: "Cansancio",
  ansioso: "Ansiedad", triste: "Sensibilidad", agradecido: "Gratitud",
};
const TAGS = {
  trabajo: "Trabajo", familia: "Familia", descanso: "Descanso", salud: "Salud",
  vinculos: "Vínculos", clima: "Clima", alimentacion: "Alimentación", estudios: "Estudios",
};

const hash = (t) => crypto.createHash("sha256").update(t).digest("hex");

function safeOffset(v) {
  return Number.isFinite(v) && Math.abs(v) <= 840 ? v : 0;
}

// Genera el enlace temporal. Revoca cualquier enlace anterior vigente.
async function createShare(userId, periodDays, tzOffsetMin) {
  await prisma.reportShare.updateMany({
    where: { userId, revokedAt: null, expiresAt: { gt: new Date() } },
    data: { revokedAt: new Date() },
  });
  const token = crypto.randomBytes(32).toString("base64url");
  const expiresAt = new Date(Date.now() + TTL_MIN * 60000);
  await prisma.reportShare.create({
    data: {
      userId,
      tokenHash: hash(token),
      periodDays,
      tzOffsetMin: safeOffset(tzOffsetMin),
      expiresAt,
    },
  });
  return { token, expiresAt };
}

async function revokeActive(userId) {
  await prisma.reportShare.updateMany({
    where: { userId, revokedAt: null, expiresAt: { gt: new Date() } },
    data: { revokedAt: new Date() },
  });
}

const avg = (arr) => {
  const v = arr.filter((x) => typeof x === "number");
  return v.length ? v.reduce((a, b) => a + b, 0) / v.length : null;
};

// Devuelve los datos del reporte, o null si el enlace no existe, venció o fue revocado.
async function getReportByToken(token) {
  const share = await prisma.reportShare.findUnique({ where: { tokenHash: hash(token) } });
  if (!share || share.revokedAt || share.expiresAt <= new Date()) return null;

  const n = share.periodDays;
  const off = share.tzOffsetMin;
  const localKey = (ms) => new Date(ms + off * 60000).toISOString().slice(0, 10);
  const now = Date.now();
  const dayKeys = Array.from({ length: n }, (_, i) => localKey(now - (n - 1 - i) * DAY_MS));

  // OJO: no se pide textNotes. Los textos del diario nunca salen del usuario.
  const rows = await prisma.journalEntry.findMany({
    where: { userId: share.userId, createdAt: { gte: new Date(now - (n + 1) * DAY_MS) } },
    orderBy: { createdAt: "asc" },
    select: {
      createdAt: true, primaryEmotion: true, emotionIntensity: true,
      energyLevel: true, stressLevel: true, sleepQuality: true, tags: true,
    },
  });
  const entries = rows.filter((e) => dayKeys.includes(localKey(e.createdAt.getTime())));

  const series = dayKeys.map((key) => {
    const es = entries.filter((e) => localKey(e.createdAt.getTime()) === key);
    return {
      date: key,
      calm: avg(es.map((e) => e.emotionIntensity)),
      energy: avg(es.map((e) => e.energyLevel)),
      stress: avg(es.map((e) => e.stressLevel)),
    };
  });

  const counts = {};
  entries.forEach((e) => { counts[e.primaryEmotion] = (counts[e.primaryEmotion] || 0) + 1; });
  const emotions = Object.entries(counts)
    .sort((a, b) => b[1] - a[1])
    .map(([k, c]) => ({ label: EMOTIONS[k] || k, count: c }));

  // Factores que se relacionan con la calma (mín. 2 registros por factor)
  const baseCalm = avg(entries.map((e) => e.emotionIntensity));
  const byTag = {};
  entries.forEach((e) => {
    if (e.emotionIntensity == null) return;
    new Set(e.tags).forEach((t) => { (byTag[t] = byTag[t] || []).push(e.emotionIntensity); });
  });
  const triggers = [];
  if (baseCalm) {
    Object.entries(byTag).forEach(([t, v]) => {
      if (v.length < 2) return;
      const pct = Math.round(((avg(v) - baseCalm) / baseCalm) * 100);
      if (Math.abs(pct) >= 8) triggers.push({ tag: TAGS[t] || t, pct, count: v.length });
    });
    triggers.sort((a, b) => Math.abs(b.pct) - Math.abs(a.pct));
  }

  return {
    periodDays: n,
    from: dayKeys[0],
    to: dayKeys[n - 1],
    entryCount: entries.length,
    daysWithEntries: new Set(entries.map((e) => localKey(e.createdAt.getTime()))).size,
    avg: {
      calm: avg(entries.map((e) => e.emotionIntensity)),
      energy: avg(entries.map((e) => e.energyLevel)),
      stress: avg(entries.map((e) => e.stressLevel)),
      sleep: avg(entries.map((e) => e.sleepQuality)),
    },
    emotions,
    series,
    triggers: triggers.slice(0, 4),
  };
}

module.exports = { createShare, revokeActive, getReportByToken };