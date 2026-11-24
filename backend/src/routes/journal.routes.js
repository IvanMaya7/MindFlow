const { Router } = require("express");
const journalController = require("../controllers/journal.controller");
const authMiddleware = require("../middlewares/auth.middleware");

const router = Router();

// Todas las rutas del diario exigen sesión iniciada
router.use(authMiddleware);

router.post("/", journalController.create);
router.get("/", journalController.list);

module.exports = router;