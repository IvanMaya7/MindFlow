import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/journal_entry.dart';
import '../data/progress_stats.dart';
import 'dart:async';
import 'package:qr_flutter/qr_flutter.dart';
import '../data/auth_service.dart' show ApiException;
import '../data/report_service.dart';

// Paleta de Progreso (tomada del diseño en Figma)
class _P {
  static const bg = Color(0xFFF4EBDD);
  static const ink = Color(0xFF1A2421);
  static const muted = Color(0xFF566A60);
  static const muted2 = Color(0xFF556F60);
  static const body = Color(0xFF263B30);
  static const forest = Color(0xFF1E3A2B);
  static const accent = Color(0xFF3B6E51);
  static const border = Color(0xFFD1E2D6);
  static const chip = Color(0xFFF1F7F2);
  static const mint = Color(0xFFE4F0E7);
  static const green = Color(0xFF10B981);
  static const cardBorder = Color(0xFFE2D9CB);
  static const selector = Color(0xFFEDE4D6);
  static const divider = Color(0xFFF0E7D9);
  static const sand = Color(0xFFD4A373);
  static const terracotta = Color(0xFFC87355);
}

TextStyle _hd(double size,
        {FontWeight w = FontWeight.w800, Color c = _P.ink, double? ls, double? h}) =>
    GoogleFonts.nunitoSans(
        fontSize: size, fontWeight: w, color: c, letterSpacing: ls, height: h);

TextStyle _tx(double size,
        {FontWeight w = FontWeight.w400, Color c = _P.muted, double? ls, double? h}) =>
    GoogleFonts.inter(
        fontSize: size, fontWeight: w, color: c, letterSpacing: ls, height: h);

// Posiciones de la gráfica (las usan el dibujo y el globo del pico)
double _cx(int i, int n, double w) => n <= 1 ? w / 2 : 8 + i / (n - 1) * (w - 16);
double _cy(double v, double h) {
  final cv = v < 0 ? 0.0 : (v > 10 ? 10.0 : v);
  return 24 + (1 - cv / 10) * (h - 24 - 8);
}

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, required this.entries});

  final List<JournalEntry> entries;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  ProgressPeriod _period = ProgressPeriod.week;
  late ProgressStats _s = ProgressStats(widget.entries, _period);

  void _setPeriod(ProgressPeriod p) {
    if (p == _period) return;
    setState(() {
      _period = p;
      _s = ProgressStats(widget.entries, p);
    });
  }

  void _soon() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Próximamente')));
  }

    bool _generating = false;

  Future<void> _generateReport() async {
    if (_generating) return;
    final days = _period == ProgressPeriod.week ? 7 : 30;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _P.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('¿Compartir tu reporte?', style: _hd(18)),
        content: Text(
          'Se generará un código QR válido por 15 minutos. Quien lo escanee verá '
          'tus promedios y tendencias de los últimos $days días.\n\n'
          'No incluye lo que escribiste en tu diario ni tu nombre. '
          'El enlace se corta al cerrar la ventana del QR.',
          style: _tx(14, c: _P.body, h: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar', style: _tx(14, w: FontWeight.w600)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: _P.forest),
            child: Text('Generar QR',
                style: _tx(14, w: FontWeight.w700, c: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _generating = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final share = await ReportService().createShare(periodDays: days);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: _P.bg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => _QrSheet(share: share),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _P.bg,
      appBar: _header(),
      bottomNavigationBar: _bottomNav(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _pageHeader(),
                const SizedBox(height: 12),
                _selector(),
                const SizedBox(height: 16),
                _summaryCard(),
                const SizedBox(height: 16),
                _chartCard(),
                const SizedBox(height: 16),
                _triggersCard(),
                const SizedBox(height: 16),
                _shareCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- Encabezado y navegación ----------------

  PreferredSizeWidget _header() {
    return AppBar(
      backgroundColor: _P.bg.withValues(alpha: 0.92),
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      toolbarHeight: 64,
      titleSpacing: 16,
      automaticallyImplyLeading: false,
      shape: Border(bottom: BorderSide(color: _P.border.withValues(alpha: 0.6))),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _P.forest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.eco, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('MINDFLOW · PROGRESO',
                    overflow: TextOverflow.ellipsis,
                    style: _tx(10, w: FontWeight.w700, c: _P.muted2, ls: 1)),
                Text('Panel Diario', style: _hd(16, c: _P.forest)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: _P.bg.withValues(alpha: 0.95),
        border: const Border(top: BorderSide(color: _P.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 'diary' le avisa al Inicio que abra el diario al regresar
              _navItem(Icons.menu_book_outlined, 'Diario',
                  onTap: () => Navigator.of(context).pop('diary')),
              _navItem(Icons.show_chart, 'Progreso', selected: true),
              _navItem(Icons.eco_outlined, 'Inicio',
                  onTap: () => Navigator.of(context).pop()),
              _navItem(Icons.local_florist_outlined, 'Recursos', onTap: _soon),
              _navItem(Icons.volunteer_activism_outlined, 'Ayuda', onTap: _soon),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label,
      {bool selected = false, VoidCallback? onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: selected ? null : onTap,
      child: SizedBox(
        width: 60,
        height: 48,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            selected
                ? Container(
                    width: 32,
                    height: 32,
                    decoration:
                        const BoxDecoration(color: _P.mint, shape: BoxShape.circle),
                    child: Icon(icon, size: 18, color: _P.forest),
                  )
                : Icon(icon, size: 21, color: _P.muted2),
            const SizedBox(height: 2),
            Text(
              label,
              style: _tx(10,
                  w: selected ? FontWeight.w700 : FontWeight.w500,
                  c: selected ? _P.forest : _P.muted2),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Cabecera de página y selector ----------------

  Widget _pageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.show_chart, size: 14, color: _P.muted),
            const SizedBox(width: 6),
            Text('MONITOREO LONGITUDINAL',
                style: _tx(11, w: FontWeight.w700, ls: 0.55)),
          ],
        ),
        const SizedBox(height: 3),
        Text('Evolución & Progreso', style: _hd(26, ls: -0.65, h: 1.25)),
        const SizedBox(height: 3),
        Text('Un resumen de cómo han ido tus registros emocionales',
            style: _tx(13, h: 1.5)),
      ],
    );
  }

  Widget _selector() {
    Widget item(String label, ProgressPeriod p) {
      final on = _period == p;
      return Expanded(
        child: GestureDetector(
          onTap: () => _setPeriod(p),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: on ? _P.forest : Colors.transparent,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Center(
              child: Text(label,
                  style: _tx(13,
                      w: on ? FontWeight.w700 : FontWeight.w500,
                      c: on ? Colors.white : _P.muted2)),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: _P.selector,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0xB3E2D9CB)),
      ),
      child: Row(
        children: [
          item('Semanal', ProgressPeriod.week),
          item('Mensual', ProgressPeriod.month),
        ],
      ),
    );
  }

  // ---------------- Tarjeta 1: resumen ----------------

  Widget _summaryCard() {
    final s = _s;
    final vs = _period == ProgressPeriod.week ? 'semana ant.' : 'mes ant.';

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 13),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _P.divider)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      _iconBox(Icons.insights),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text('Resumen de tu periodo', style: _hd(15, h: 1.25)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: _P.chip,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: _P.border.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            color: _P.green, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Text('${s.constancyPct}% constancia',
                          style: _tx(11, w: FontWeight.w600, c: _P.accent)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: _P.chip,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _P.border.withValues(alpha: 0.6)),
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  for (final (text, bold) in s.summarySegments)
                    TextSpan(
                      text: text,
                      style: bold
                          ? _tx(13.5, w: FontWeight.w700, c: _P.ink, h: 1.6)
                          : _tx(13.5, c: _P.body, h: 1.6),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _mini('Calma prom.', Icons.spa_outlined, s.avgCalm, '/10', 10,
                      _P.accent, _delta(ProgressStats.deltaPct(s.avgCalm, s.prevCalm), vs)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _mini(
                      'Nivel Energía',
                      Icons.wb_sunny_outlined,
                      s.avgEnergy,
                      '/10',
                      10,
                      _P.accent,
                      _delta(ProgressStats.deltaPct(s.avgEnergy, s.prevEnergy), vs)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _mini(
                      'Estrés prom.',
                      Icons.psychology_outlined,
                      s.avgStress,
                      '/10',
                      10,
                      _P.terracotta,
                      _delta(ProgressStats.deltaPct(s.avgStress, s.prevStress), vs,
                          lowerIsBetter: true)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _mini(
                      'Sueño prom.',
                      Icons.nightlight_outlined,
                      s.avgSleep,
                      'hrs',
                      12,
                      _P.accent,
                      _delta(ProgressStats.deltaPct(s.avgSleep, s.prevSleep), vs)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Texto y color del cambio contra el periodo anterior.
  (String, Color) _delta(int? pct, String vs, {bool lowerIsBetter = false}) {
    if (pct == null) return ('Sin periodo previo', _P.muted2);
    if (pct == 0) return ('= Sin cambios vs. $vs', _P.muted2);
    final up = pct > 0;
    final good = lowerIsBetter ? !up : up;
    final arrow = up ? '↑ +$pct%' : '↓ $pct%';
    return ('$arrow vs. $vs', good ? _P.accent : _P.terracotta);
  }

  Widget _mini(String label, IconData icon, double? value, String unit, double max,
      Color bar, (String, Color) caption) {
    final progress = value == null ? 0.0 : (value / max).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _P.chip,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _P.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: _tx(11, w: FontWeight.w600)),
              ),
              Icon(icon, size: 13, color: _P.accent),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value == null ? '–' : value.toStringAsFixed(1),
                  style: _hd(22)),
              const SizedBox(width: 2),
              Text(unit, style: _tx(11, w: FontWeight.w500, c: _P.muted2)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Stack(
              children: [
                Container(height: 6, color: _P.border.withValues(alpha: 0.6)),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(height: 6, color: bar),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(caption.$1,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _tx(10, w: FontWeight.w700, c: caption.$2)),
        ],
      ),
    );
  }

  // ---------------- Tarjeta 2: gráfica ----------------

  Widget _chartCard() {
    final s = _s;
    final series = s.series;
    final hasData = series.any((p) => p.hasAny);
    final peak = s.peakIndex;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        _period == ProgressPeriod.week
                            ? 'Variación Emocional Semanal'
                            : 'Variación Emocional Mensual',
                        style: _hd(15, h: 1.25)),
                    Text('Tendencias registradas por día', style: _tx(12, h: 1.5)),
                  ],
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _P.chip,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _P.border.withValues(alpha: 0.6)),
                ),
                child: const Icon(Icons.show_chart, size: 15, color: _P.accent),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _legend(_P.accent, 'Calma'),
              const SizedBox(width: 16),
              _legend(_P.sand, 'Energía'),
              const SizedBox(width: 16),
              _legend(_P.terracotta, 'Estrés'),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(13, 17, 13, 13),
            decoration: BoxDecoration(
              color: _P.chip,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _P.border.withValues(alpha: 0.6)),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 144,
                  child: !hasData
                      ? Center(
                          child: Text('Aún no hay datos suficientes en este periodo',
                              textAlign: TextAlign.center, style: _tx(12)),
                        )
                      : LayoutBuilder(
                          builder: (context, c) {
                            final w = c.maxWidth;
                            return Stack(
                              children: [
                                CustomPaint(
                                  size: Size(w, 144),
                                  painter: _ChartPainter(series, peak),
                                ),
                                if (peak != null)
                                  Positioned(
                                    left: (_cx(peak, series.length, w) - 52)
                                        .clamp(0.0, w - 104),
                                    width: 104,
                                    top: 0,
                                    child: Center(child: _peakTooltip(series[peak])),
                                  ),
                              ],
                            );
                          },
                        ),
                ),
                const SizedBox(height: 8),
                _xLabels(series, peak),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: _P.mint.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE3EDE6)),
            ),
            child: Row(
              children: [
                const Icon(Icons.trending_up, size: 15, color: _P.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(s.stabilityMessage,
                      style: _tx(12, w: FontWeight.w500, c: _P.forest, h: 1.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: _tx(11, w: FontWeight.w600)),
      ],
    );
  }

  Widget _peakTooltip(DayPoint p) {
    final when = _period == ProgressPeriod.week
        ? weekdayShort[p.day.weekday - 1]
        : '${p.day.day}/${p.day.month}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: _P.forest,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
                color: Color(0xFF34D399), shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text('Pico ${p.calm!.toStringAsFixed(1)} ($when)',
                overflow: TextOverflow.ellipsis,
                style: _tx(10, c: Colors.white, h: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _xLabels(List<DayPoint> series, int? peak) {
    if (_period == ProgressPeriod.week) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < series.length; i++)
              Text(
                weekdayShort[series[i].day.weekday - 1],
                style: _tx(11,
                    w: i == peak ? FontWeight.w700 : FontWeight.w500,
                    c: i == peak ? _P.forest : _P.muted2),
              ),
          ],
        ),
      );
    }
    String f(DayPoint p) => '${p.day.day}/${p.day.month}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(f(series.first), style: _tx(11, w: FontWeight.w500, c: _P.muted2)),
          Text(f(series[series.length ~/ 2]),
              style: _tx(11, w: FontWeight.w500, c: _P.muted2)),
          Text(f(series.last), style: _tx(11, w: FontWeight.w500, c: _P.muted2)),
        ],
      ),
    );
  }

  // ---------------- Tarjeta 3: desencadenantes ----------------

  Widget _triggersCard() {
    final triggers = _s.triggers;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Posibles Desencadenantes', style: _hd(15, h: 1.25)),
                    Text('Cómo se relaciona cada factor con tu calma',
                        style: _tx(12, h: 1.5)),
                  ],
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _P.chip,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _P.border.withValues(alpha: 0.6)),
                ),
                child: const Icon(Icons.sell_outlined, size: 15, color: _P.accent),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (triggers.isEmpty)
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: _P.chip,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _P.border.withValues(alpha: 0.6)),
              ),
              child: Text(
                'Con más registros que incluyan factores (#Trabajo, #Familia…) verás aquí qué se relaciona con tu calma.',
                style: _tx(12, h: 1.5),
              ),
            )
          else
            for (var i = 0; i < triggers.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _triggerItem(triggers[i]),
            ],
        ],
      ),
    );
  }

  Widget _triggerItem(Trigger t) {
    late final String badge;
    late final Color bg, border, fg;
    late final String text;

    if (t.impactPct > 0) {
      badge = 'Factor Protector (+${t.impactPct}%)';
      bg = _P.mint;
      border = const Color(0x6688B797);
      fg = _P.accent;
      text =
          'Los días con este factor tu calma promedio fue ${t.impactPct}% mayor. Aparece en ${t.count} registros.';
    } else if (t.impactPct <= -20) {
      badge = 'Impacto Alto (${t.impactPct}%)';
      bg = const Color(0xFFFFDAD6);
      border = const Color(0xFFFFB4AB);
      fg = const Color(0xFFBA1A1A);
      text =
          'Los días con este factor tu calma promedio fue ${-t.impactPct}% menor. Aparece en ${t.count} registros.';
    } else {
      badge = 'Impacto Moderado (${t.impactPct}%)';
      bg = const Color(0xFFF9F1E6);
      border = const Color(0xFFECDAC2);
      fg = const Color(0xFF8A5B28);
      text =
          'Los días con este factor tu calma promedio fue ${-t.impactPct}% menor. Aparece en ${t.count} registros.';
    }

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _P.chip,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _P.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: _P.border.withValues(alpha: 0.7)),
                ),
                child: Text(tagLabels[t.tag] ?? '#${t.tag}',
                    style: _tx(12, w: FontWeight.w700, c: _P.forest)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: border),
                ),
                child: Text(badge, style: _tx(11, w: FontWeight.w600, c: fg)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(text, style: _tx(12, h: 1.25)),
        ],
      ),
    );
  }

  // ---------------- Tarjeta 4: terapeuta (próximamente) ----------------
  Widget _shareCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 13),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _P.divider)),
            ),
            child: Row(
              children: [
                _iconBox(Icons.qr_code_2),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Compartir con tu Terapeuta', style: _hd(15, h: 1.25)),
                      Text('Reporte con tus métricas y tendencias',
                          style: _tx(11, h: 1.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: _P.chip,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _P.border.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_clock_outlined, size: 18, color: _P.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Genera un código QR temporal (15 min) con tus promedios, '
                    'gráfica y factores del periodo que estás viendo. No incluye '
                    'tus textos ni tu nombre.',
                    style: _tx(11, h: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Material(
            color: _P.forest,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _generating ? null : _generateReport,
              child: SizedBox(
                height: 48,
                child: Center(
                  child: _generating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.qr_code_2, size: 16, color: Colors.white),
                            const SizedBox(width: 8),
                            Text('Generar Reporte y Mostrar QR',
                                style: _tx(14, w: FontWeight.w700, c: Colors.white)),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _iconBox(IconData icon) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: _P.mint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 15, color: _P.accent),
    );
  }
}

// ---------------- Dibujo de la gráfica ----------------

class _ChartPainter extends CustomPainter {
  _ChartPainter(this.series, this.peak);

  final List<DayPoint> series;
  final int? peak;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = _P.border.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    for (final v in [0.0, 5.0, 10.0]) {
      final y = _cy(v, size.height);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    _line(canvas, size, (p) => p.stress, _P.terracotta, fill: false);
    _line(canvas, size, (p) => p.energy, _P.sand, fill: false);
    _line(canvas, size, (p) => p.calm, _P.accent, fill: true);

    final pk = peak;
    if (pk != null && series[pk].calm != null) {
      final o = Offset(
          _cx(pk, series.length, size.width), _cy(series[pk].calm!, size.height));
      canvas.drawCircle(o, 6, Paint()..color = _P.accent.withValues(alpha: 0.25));
      canvas.drawCircle(o, 3.5, Paint()..color = _P.forest);
    }
  }

  void _line(Canvas canvas, Size size, double? Function(DayPoint) pick, Color color,
      {required bool fill}) {
    final pts = <Offset>[];
    for (var i = 0; i < series.length; i++) {
      final v = pick(series[i]);
      if (v != null) {
        pts.add(Offset(_cx(i, series.length, size.width), _cy(v, size.height)));
      }
    }
    if (pts.isEmpty) return;

    if (pts.length >= 2) {
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length; i++) {
        final a = pts[i - 1], b = pts[i];
        final mx = (a.dx + b.dx) / 2;
        path.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
      }

      if (fill) {
        final area = Path.from(path)
          ..lineTo(pts.last.dx, size.height)
          ..lineTo(pts.first.dx, size.height)
          ..close();
        canvas.drawPath(
          area,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0)],
            ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
        );
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
    }

    for (final p in pts) {
      canvas.drawCircle(p, 3, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) => true;
}

// ---------------- Ventana del QR ----------------

class _QrSheet extends StatefulWidget {
  const _QrSheet({required this.share});

  final ReportShare share;

  @override
  State<_QrSheet> createState() => _QrSheetState();
}

class _QrSheetState extends State<_QrSheet> {
  Timer? _timer;
  Duration _left = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final left = widget.share.expiresAt.difference(DateTime.now());
    if (!mounted) return;
    setState(() => _left = left.isNegative ? Duration.zero : left);
    if (left.isNegative) _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Al cerrar la ventana, el enlace deja de funcionar.
    unawaited(ReportService().revoke().catchError((_) {}));
    super.dispose();
  }

  String get _countdown {
    final m = _left.inMinutes.toString().padLeft(2, '0');
    final s = (_left.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final expired = _left == Duration.zero;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Muestra este código a tu terapeuta', style: _hd(18)),
            const SizedBox(height: 4),
            Text('Al escanearlo verá tu reporte en su navegador.',
                textAlign: TextAlign.center, style: _tx(13, h: 1.5)),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _P.border),
              ),
              child: expired
                  ? const SizedBox(
                      width: 220,
                      height: 220,
                      child: Center(
                        child: Icon(Icons.timer_off_outlined,
                            size: 48, color: _P.muted2),
                      ),
                    )
                  : QrImageView(
                      data: widget.share.url,
                      size: 220,
                      backgroundColor: Colors.white,
                    ),
            ),
            const SizedBox(height: 14),
            Text(
              expired ? 'El código expiró' : 'Vence en $_countdown',
              style: _tx(14, w: FontWeight.w700, c: _P.forest),
            ),
            const SizedBox(height: 4),
            Text(
              'Solo métricas y tendencias. Sin tus textos ni tu nombre.',
              textAlign: TextAlign.center,
              style: _tx(12, h: 1.5),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: _P.forest,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Dejar de compartir',
                    style: _tx(14, w: FontWeight.w700, c: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Tarjeta base ----------------

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _P.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}