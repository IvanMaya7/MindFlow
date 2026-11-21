const { z } = require('zod');
const authService = require('../services/auth.service');

const registerSchema = z.object({
  email: z.string().email('Correo inválido'),
  password: z.string().min(8, 'La contraseña debe tener al menos 8 caracteres'),
  displayName: z.string().min(2, 'El nombre es muy corto').max(60),
  allowAiAnalysis: z.boolean().optional().default(false),
  emergencyContact: z.object({
    name: z.string().min(2, 'El nombre del contacto es muy corto').max(80),
    phone: z.string().min(7, 'El teléfono del contacto no es válido').max(20),
    relation: z.string().max(40).optional(),
  }),
});

const loginSchema = z.object({
  email: z.string().email('Correo inválido'),
  password: z.string().min(1, 'La contraseña es obligatoria'),
});

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

module.exports = { register, login, me };
