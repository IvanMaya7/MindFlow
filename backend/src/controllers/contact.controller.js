const contactsService = require("../services/contacts.service");

async function list(req, res, next) {
  try {
    const userId = req.userId; // ← igual que en report.controller.js
    const contacts = await contactsService.listContacts(userId);
    res.json({ contacts });
  } catch (err) {
    next(err);
  }
}

module.exports = { list };