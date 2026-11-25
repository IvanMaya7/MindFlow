const { Router } = require("express");
const authMiddleware = require("../middlewares/auth.middleware"); 
const ctrl = require("../controllers/report.controller");

const router = Router();
router.use(authMiddleware);

router.post("/share", ctrl.createShare);
router.delete("/share", ctrl.revokeShare);

module.exports = router;