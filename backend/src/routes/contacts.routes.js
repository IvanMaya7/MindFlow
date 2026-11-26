const { Router } = require("express");
const authMiddleware = require("../middlewares/auth.middleware");
const ctrl = require("../controllers/contacts.controller");

const router = Router();
router.use(authMiddleware);
router.get("/", ctrl.list);

module.exports = router;