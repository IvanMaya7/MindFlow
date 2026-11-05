const { port } = require('./config/env');
const app = require('./app');

app.listen(port, () => {
  console.log(`MindFlow API escuchando en http://localhost:${port}/api`);
});
