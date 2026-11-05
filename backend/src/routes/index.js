const router = require('express').Router();
const { requireAuth } = require('../middleware/auth');
const auth = require('../controllers/auth.controller');
const journal = require('../controllers/journal.controller');
const contacts = require('../controllers/contacts.controller');
const resources = require('../controllers/resources.controller');

router.get('/health', (req, res) => res.json({ status: 'ok' }));

// Auth
router.post('/auth/register', auth.register);
router.post('/auth/login', auth.login);
router.get('/me', requireAuth, auth.me);
router.patch('/me', requireAuth, auth.updatePreferences);

// Diario emocional
router.get('/journal', requireAuth, journal.list);
router.get('/journal/stats', requireAuth, journal.stats);
router.post('/journal', requireAuth, journal.create);
router.get('/journal/:id', requireAuth, journal.getOne);
router.delete('/journal/:id', requireAuth, journal.remove);

// Red de apoyo
router.get('/contacts', requireAuth, contacts.list);
router.post('/contacts', requireAuth, contacts.create);
router.delete('/contacts/:id', requireAuth, contacts.remove);

// Psicoeducación
router.get('/resources', requireAuth, resources.list);

module.exports = router;
