const esc = (s) =>
  String(s).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

const fmt = (v, d = 1) => (v == null ? "–" : v.toFixed(d));
const dmy = (iso) => iso.slice(8, 10) + "/" + iso.slice(5, 7);

function chart(points) {
  const W = 640, H = 200, P = 28, n = points.length;
  const x = (i) => P + (n <= 1 ? (W - 2 * P) / 2 : (i / (n - 1)) * (W - 2 * P));
  const y = (v) => H - P - (v / 10) * (H - 2 * P);
  const line = (key, color) => {
    const pts = points
      .map((p, i) => (p[key] == null ? null : [x(i).toFixed(1), y(p[key]).toFixed(1)]))
      .filter(Boolean);
    if (!pts.length) return "";
    const poly = pts.length > 1
      ? `<polyline points="${pts.map((p) => p.join(",")).join(" ")}" fill="none" stroke="${color}" stroke-width="2.2" stroke-linejoin="round"/>`
      : "";
    const dots = pts.map((p) => `<circle cx="${p[0]}" cy="${p[1]}" r="3" fill="${color}"/>`).join("");
    return poly + dots;
  };
  const grid = [0, 5, 10]
    .map((v) => `<line x1="${P}" x2="${W - P}" y1="${y(v)}" y2="${y(v)}" stroke="#d1e2d6"/><text x="4" y="${y(v) + 4}" font-size="10" fill="#566a60">${v}</text>`)
    .join("");
  return `<svg viewBox="0 0 ${W} ${H}" width="100%" role="img" aria-label="Calma, energía y estrés por día">${grid}${line("stress", "#c87355")}${line("energy", "#d4a373")}${line("calm", "#3b6e51")}</svg>`;
}

const page = (body) => `<!doctype html>
<html lang="es"><head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex, nofollow">
<title>Reporte de seguimiento emocional</title>
<style>
  body{margin:0;background:#f4ebdd;color:#1a2421;font-family:system-ui,-apple-system,Segoe UI,Roboto,sans-serif;line-height:1.5}
  main{max-width:680px;margin:0 auto;padding:20px 16px 40px}
  h1{font-size:22px;margin:4px 0}
  h2{font-size:16px;margin:0 0 10px}
  .muted{color:#566a60;font-size:13px}
  .card{background:#fff;border:1px solid #e2d9cb;border-radius:16px;padding:18px;margin-top:14px}
  .grid{display:grid;grid-template-columns:1fr 1fr;gap:10px}
  .stat{background:#f1f7f2;border:1px solid #d1e2d6;border-radius:12px;padding:12px}
  .stat b{display:block;font-size:24px}
  .legend span{display:inline-block;margin-right:14px;font-size:12px}
  .legend i{display:inline-block;width:10px;height:10px;border-radius:50%;margin-right:5px}
  table{width:100%;border-collapse:collapse;font-size:14px}
  td{padding:7px 0;border-bottom:1px solid #f0e7d9}
  td:last-child{text-align:right}
  .note{font-size:12px;color:#566a60;margin-top:16px}
</style></head><body><main>${body}</main></body></html>`;

function renderReport(r) {
  const empty = r.entryCount === 0;
  const emotions = r.emotions.length
    ? `<table>${r.emotions.map((e) => `<tr><td>${esc(e.label)}</td><td>${e.count} registro(s)</td></tr>`).join("")}</table>`
    : '<p class="muted">Sin registros en este periodo.</p>';
  const triggers = r.triggers.length
    ? `<table>${r.triggers
        .map((t) => `<tr><td>#${esc(t.tag)}</td><td>${t.pct > 0 ? "+" : ""}${t.pct}% de calma vs. su promedio (${t.count} registros)</td></tr>`)
        .join("")}</table>`
    : '<p class="muted">Aún no hay suficientes registros con factores para detectar relaciones.</p>';

  return page(`
    <div class="muted">MINDFLOW · REPORTE DE SEGUIMIENTO EMOCIONAL</div>
    <h1>Últimos ${r.periodDays} días</h1>
    <div class="muted">Del ${dmy(r.from)} al ${dmy(r.to)} · ${r.daysWithEntries} de ${r.periodDays} días con registro · ${r.entryCount} registros</div>

    <div class="card"><h2>Promedios</h2>
      <div class="grid">
        <div class="stat">Calma<b>${fmt(r.avg.calm)}<small>/10</small></b></div>
        <div class="stat">Energía<b>${fmt(r.avg.energy)}<small>/10</small></b></div>
        <div class="stat">Estrés<b>${fmt(r.avg.stress)}<small>/10</small></b></div>
        <div class="stat">Sueño<b>${fmt(r.avg.sleep)}<small> hrs</small></b></div>
      </div>
    </div>

    ${empty ? "" : `<div class="card"><h2>Evolución diaria</h2>
      <div class="legend"><span><i style="background:#3b6e51"></i>Calma</span><span><i style="background:#d4a373"></i>Energía</span><span><i style="background:#c87355"></i>Estrés</span></div>
      ${chart(r.series)}</div>`}

    <div class="card"><h2>Estados predominantes</h2>${emotions}</div>
    <div class="card"><h2>Factores y su relación con la calma</h2>${triggers}</div>

    <p class="note">Información autorreportada por la persona usuaria de MindFlow. Incluye solo métricas y tendencias; no contiene sus textos ni datos de identidad. No constituye un diagnóstico. Este enlace es temporal y puede dejar de funcionar en cualquier momento.</p>
  `);
}

function renderExpired() {
  return page(`
    <div class="card" style="margin-top:40px;text-align:center">
      <h1>Este enlace ya no está disponible</h1>
      <p class="muted">Venció o la persona dejó de compartirlo. Pídele que genere uno nuevo desde la app.</p>
    </div>`);
}

module.exports = { renderReport, renderExpired };