const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const authRoutes = require('./routes/auth.routes');
const errorHandler = require('./middlewares/error.middleware');
const journalRoutes = require("./routes/journal.routes");

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json());

app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} ${req.method} ${req.url}`);
  next();
});

app.set('trust proxy', 1);

app.get('/health', (req, res) => res.json({ status: 'ok', service: 'auth-service' }));
app.use('/api/auth', authRoutes);
app.use("/api/journal", journalRoutes);

app.use(errorHandler);

module.exports = app;
