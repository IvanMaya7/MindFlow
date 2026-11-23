const { z } = require("zod");
const authService = require("../services/auth.service");

const nameChars = /^[\p{L}\p{M}' .-]+$/u;
const contactNameChars = /^[\p{L}\p{M}' .()-]+$/u;
const hasTwoLetters = (v) => (v.match(/\p{L}/gu) || []).length >= 2;

const emailField = z
  .string({ required_error: "El correo es obligatorio" })
  .trim()
  .toLowerCase()
  .max(254, "El correo es demasiado largo")
  .email("Correo inválido");

const passwordRule = z
  .string({ required_error: "La contraseña es obligatoria" })
  .min(8, "La contraseña debe tener al menos 8 caracteres")
  .max(72, "La contraseña no puede tener más de 72 caracteres")
  .regex(/[A-Za-z]/, "La contraseña debe incluir al menos una letra")
  .regex(/[0-9]/, "La contraseña debe incluir al menos un número");

const registerSchema = z.object({
  email: emailField,
  password: passwordRule,
  displayName: z
    .string({ required_error: "El nombre es obligatorio" })
    .trim()
    .min(2, "El nombre es muy corto")
    .max(60, "El nombre es muy largo")
    .regex(nameChars, "El nombre solo puede tener letras y espacios")
    .refine(hasTwoLetters, "El nombre debe tener al menos 2 letras")
    .transform((v) => v.replace(/\s+/g, " ")),
  allowAiAnalysis: z.boolean().optional().default(false),
  emergencyContact: z.object({
    name: z
      .string({ required_error: "El nombre del contacto es obligatorio" })
      .trim()
      .min(2, "El nombre del contacto es muy corto")
      .max(80, "El nombre del contacto es muy largo")
      .regex(
        contactNameChars,
        "El nombre del contacto solo puede tener letras y espacios",
      )
      .refine(
        hasTwoLetters,
        "El nombre del contacto debe tener al menos 2 letras",
      )
      .transform((v) => v.replace(/\s+/g, " ")),
    phone: z
      .string()
      .trim()
      .regex(/^[+0-9\s()-]{7,20}$/, "El teléfono del contacto no es válido")
      .refine(
        (v) => v.replace(/\D/g, "").length >= 10,
        "El teléfono debe tener al menos 10 dígitos",
      ),
    relation: z
      .string({ required_error: 'El parentesco es obligatorio' })
      .trim()
      .min(1, 'El parentesco es obligatorio')
      .max(40, 'El parentesco es muy largo'),
  }),
});

const loginSchema = z.object({
  email: emailField,
  password: z
    .string({ required_error: "La contraseña es obligatoria" })
    .min(1, "La contraseña es obligatoria")
    .max(128),
});

const checkEmailSchema = z.object({ email: emailField });

const checkEmail = async (req, res, next) => {
  try {
    const { email } = checkEmailSchema.parse(req.body);
    const exists = await authService.emailExists(email);
    res.json({ available: !exists });
  } catch (err) {
    next(err);
  }
};

const register = async (req, res, next) => {
  try {
    const data = registerSchema.parse(req.body);
    const result = await authService.register(data);
    res.status(201).json(result);
  } catch (err) {
    next(err);
  }
};

const login = async (req, res, next) => {
  try {
    const data = loginSchema.parse(req.body);
    const result = await authService.login(data);
    res.json(result);
  } catch (err) {
    next(err);
  }
};

const me = async (req, res, next) => {
  try {
    const user = await authService.getProfile(req.userId);
    res.json({ user });
  } catch (err) {
    next(err);
  }
};

module.exports = { register, login, me, checkEmail };
