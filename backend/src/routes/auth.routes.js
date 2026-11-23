const { Router } = require('express');
const controller = require('../controllers/auth.controller');
const authMiddleware = require('../middlewares/auth.middleware');
const { authLimiter, resetLimiter } = require('../middlewares/rateLimit.middleware');

const router = Router();

router.post('/check-email', authLimiter, controller.checkEmail);
router.post('/register', controller.register);
router.post('/login', controller.login);
router.get('/me', authMiddleware, controller.me);
router.post('/forgot-password', resetLimiter, controller.forgotPassword);
router.post('/reset-password', resetLimiter, controller.resetPassword);

module.exports = router;
