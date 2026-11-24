const prisma = require("../lib/prisma");

const createEntry = async (userId, data) =>
  prisma.journalEntry.create({ data: { userId, ...data } });

const listEntries = async (userId, { limit, offset }) => {
  const [entries, total] = await Promise.all([
    prisma.journalEntry.findMany({
      where: { userId },
      orderBy: { entryDate: "desc" },
      take: limit,
      skip: offset,
    }),
    prisma.journalEntry.count({ where: { userId } }),
  ]);
  return { entries, total };
};

module.exports = { createEntry, listEntries };