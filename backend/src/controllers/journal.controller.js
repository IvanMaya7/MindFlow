const { z } = require("zod");
const journalService = require("../services/journal.service");

// Valores permitidos (claves estables que se guardan en la base)
const EMOTIONS = ["calma", "esperanzado", "cansado", "ansioso", "triste", "agradecido"];
const SENSATIONS = [
  "ligero",
  "tension_hombros",
  "respiracion_tranquila",
  "inquietud",
  "pecho_oprimido",
];
const TAGS = [
  "trabajo",
  "familia",
  "descanso",
  "salud",
  "vinculos",
  "clima",
  "alimentacion",
  "estudios",
];

const unique = (arr) => [...new Set(arr)];

const scale = (label) =>
  z
    .number({ invalid_type_error: `${label} debe ser un número` })
    .int(`${label} debe ser un número entero`)
    .min(1, `${label} debe estar entre 1 y 10`)
    .max(10, `${label} debe estar entre 1 y 10`)
    .optional();

const createSchema = z.object({
  primaryEmotion: z.enum(EMOTIONS, {
    errorMap: () => ({ message: "Elige una emoción válida" }),
  }),
  bodySensations: z
    .array(z.enum(SENSATIONS, { errorMap: () => ({ message: "Sensación no válida" }) }))
    .optional()
    .default([])
    .transform(unique),
  emotionIntensity: scale("La calma"),
  energyLevel: scale("La energía"),
  stressLevel: scale("El estrés"),
  sleepQuality: z
    .number({ invalid_type_error: "Las horas de sueño deben ser un número" })
    .int("Las horas de sueño deben ser un número entero")
    .min(0, "Las horas de sueño no son válidas")
    .max(24, "Las horas de sueño no son válidas")
    .optional(),
  tags: z
    .array(z.enum(TAGS, { errorMap: () => ({ message: "Factor no válido" }) }))
    .optional()
    .default([])
    .transform(unique),
  textNotes: z
    .string()
    .trim()
    .max(5000, "El texto es demasiado largo (máximo 5000 caracteres)")
    .optional()
    .transform((v) => (v ? v : undefined)),
});

const listSchema = z.object({
  limit: z.coerce.number().int().min(1).max(100).default(20),
  offset: z.coerce.number().int().min(0).default(0),
});

const create = async (req, res, next) => {
  try {
    const data = createSchema.parse(req.body);
    const entry = await journalService.createEntry(req.userId, data);
    res.status(201).json({ entry });
  } catch (err) {
    next(err);
  }
};

const list = async (req, res, next) => {
  try {
    const query = listSchema.parse(req.query);
    const result = await journalService.listEntries(req.userId, query);
    res.json(result);
  } catch (err) {
    next(err);
  }
};

module.exports = { create, list };