const { z } = require("zod");
const reportService = require("../services/report.service");
const { renderReport, renderExpired } = require("../views/report.view");

const shareSchema = z.object({
  periodDays: z.union([z.literal(7), z.literal(30)]).default(7),
});

async function createShare(req, res, next) {
  try {
    const { periodDays } = shareSchema.parse(req.body ?? {});
    const tz = parseInt(req.query.tz, 10);
    const { token, expiresAt } = await reportService.createShare(
      req.user.id, // ← igual que en journal.controller.js
      periodDays,
      Number.isNaN(tz) ? 0 : tz
    );
    res.status(201).json({
      url: `${process.env.PUBLIC_BASE_URL}/r/${token}`,
      expiresAt,
    });
  } catch (err) {
    next(err);
  }
}

async function revokeShare(req, res, next) {
  try {
    await reportService.revokeActive(req.user.id); // ← igual que arriba
    res.status(204).end();
  } catch (err) {
    next(err);
  }
}

// Página pública que abre el QR (sin sesión: el código del enlace es la credencial)
async function publicView(req, res, next) {
  try {
    res.set({
      "Cache-Control": "no-store",
      "X-Robots-Tag": "noindex, nofollow",
      "Referrer-Policy": "no-referrer",
    });
    const data = await reportService.getReportByToken(req.params.token);
    if (!data) return res.status(410).type("html").send(renderExpired());
    res.type("html").send(renderReport(data));
  } catch (err) {
    next(err);
  }
}

module.exports = { createShare, revokeShare, publicView };