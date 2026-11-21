const app = require('./app');
const { port } = require('./config/env');

app.listen(port, () => {
  console.log(`auth-service escuchando en el puerto ${port}`);
});
