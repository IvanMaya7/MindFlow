const nodemailer = require('nodemailer');

let transporter;
function getTransporter() {
  if (!transporter) {
    transporter = nodemailer.createTransport({
      host: 'smtp.gmail.com',
      port: 465,
      secure: true,
      auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS },
    });
  }
  return transporter;
}

async function sendPasswordResetCode(to, code) {
  await getTransporter().sendMail({
    from: `"MindFlow" <${process.env.SMTP_USER}>`,
    to,
    subject: 'Tu código para recuperar tu contraseña',
    text: `Tu código de MindFlow es ${code}. Vence en 15 minutos. Si no lo pediste, ignora este correo.`,
    html: `
      <div style="font-family:Arial,sans-serif;max-width:420px;margin:auto">
        <h2>Recupera tu contraseña</h2>
        <p>Usa este código en la app:</p>
        <p style="font-size:32px;letter-spacing:6px;font-weight:bold">${code}</p>
        <p>Vence en 15 minutos. Si no lo pediste, ignora este correo.</p>
      </div>`,
  });
}

module.exports = { sendPasswordResetCode };