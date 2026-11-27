import 'journal_entry.dart';

enum ProgressPeriod { week, month }

const emotionLabels = {
  'calma': 'Calma',
  'esperanzado': 'Esperanzado',
  'cansado': 'Cansancio',
  'ansioso': 'Ansiedad',
  'triste': 'Sensibilidad',
  'agradecido': 'Gratitud',
};

const tagLabels = {
  'trabajo': '#Trabajo',
  'familia': '#Familia',
  'descanso': '#Descanso',
  'salud': '#Salud',
  'vinculos': '#Vínculos',
  'clima': '#Clima',
  'alimentacion': '#Alimentación',
  'estudios': '#Estudios',
};

const weekdayShort = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
const _weekdayFull = [
  'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'
];

DateTime _d(DateTime d) => DateTime(d.year, d.month, d.day);

/// Promedio de un día para cada métrica (null si ese día no hubo dato).
class DayPoint {
  DayPoint(this.day, {this.calm, this.energy, this.stress});
  final DateTime day;
  final double? calm;
  final double? energy;
  final double? stress;

  bool get hasAny => calm != null || energy != null || stress != null;
}

class Trigger {
  Trigger(this.tag, this.impactPct, this.count);
  final String tag;
  final int impactPct; // % de diferencia de calma vs tu promedio
  final int count; // en cuántos registros apareció
}

class ProgressStats {
  ProgressStats(List<JournalEntry> all, this.period)
      : periodDays = period == ProgressPeriod.week ? 7 : 30 {
    final today = _d(DateTime.now());
    start = DateTime(today.year, today.month, today.day - (periodDays - 1));
    final prevStart =
        DateTime(start.year, start.month, start.day - periodDays);
    current = all.where((e) => !_d(e.createdAt).isBefore(start)).toList();
    previous = all.where((e) {
      final d = _d(e.createdAt);
      return !d.isBefore(prevStart) && d.isBefore(start);
    }).toList();
  }

  final ProgressPeriod period;
  final int periodDays;
  late final DateTime start;
  late final List<JournalEntry> current;
  late final List<JournalEntry> previous;

  static double? _avg(List<JournalEntry> l, int? Function(JournalEntry) f) {
    final v = l.map(f).whereType<int>().toList();
    if (v.isEmpty) return null;
    return v.reduce((a, b) => a + b) / v.length;
  }

  double? get avgCalm => _avg(current, (e) => e.emotionIntensity);
  double? get avgEnergy => _avg(current, (e) => e.energyLevel);
  double? get avgStress => _avg(current, (e) => e.stressLevel);
  double? get avgSleep => _avg(current, (e) => e.sleepHours);

  double? get prevCalm => _avg(previous, (e) => e.emotionIntensity);
  double? get prevEnergy => _avg(previous, (e) => e.energyLevel);
  double? get prevStress => _avg(previous, (e) => e.stressLevel);
  double? get prevSleep => _avg(previous, (e) => e.sleepHours);

  /// Cambio porcentual contra el periodo anterior (null si no hay con qué comparar).
  static int? deltaPct(double? cur, double? prev) {
    if (cur == null || prev == null || prev == 0) return null;
    return ((cur - prev) / prev * 100).round();
  }

  bool get isEmpty => current.isEmpty;

  /// Un punto por día del periodo, de más viejo a hoy.
  List<DayPoint> get series => List.generate(periodDays, (i) {
        final day = DateTime(start.year, start.month, start.day + i);
        final es = current.where((e) => _d(e.createdAt) == day).toList();
        return DayPoint(
          day,
          calm: _avg(es, (e) => e.emotionIntensity),
          energy: _avg(es, (e) => e.energyLevel),
          stress: _avg(es, (e) => e.stressLevel),
        );
      });

  /// % de días del periodo con al menos un registro.
  int get constancyPct {
    final days = current.map((e) => _d(e.createdAt)).toSet().length;
    return (days / periodDays * 100).round();
  }

  /// Índice (en [series]) del día con más calma, o null si no hay datos de calma.
  int? get peakIndex {
    final s = series;
    int? best;
    for (var i = 0; i < s.length; i++) {
      final c = s[i].calm;
      if (c == null) continue;
      if (best == null || c > s[best].calm!) best = i;
    }
    return best;
  }

  List<String> get dominantEmotions {
    final counts = <String, int>{};
    for (final e in current) {
      counts[e.primaryEmotion] = (counts[e.primaryEmotion] ?? 0) + 1;
    }
    final keys = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return keys.take(2).map((k) => emotionLabels[k] ?? k).toList();
  }

  static String dayName(DateTime d) =>
      '${_weekdayFull[d.weekday - 1]} ${d.day}/${d.month}';

  /// Resumen en lenguaje natural: lista de (texto, ¿va en negritas?).
  List<(String, bool)> get summarySegments {
    if (current.isEmpty) {
      return [
        (
          'Aún no hay registros en este periodo. Cuando escribas en tu diario, aquí verás un resumen de cómo vas.',
          false
        ),
      ];
    }
    final dom = dominantEmotions;
    final segs = <(String, bool)>[
      ('Durante los últimos $periodDays días, tu estado emocional predominante ha sido de ', false),
      (dom.first, true),
      if (dom.length > 1) ...[(' y ', false), (dom[1], true)],
      ('.', false),
    ];
    final p = peakIndex;
    if (p != null) {
      final point = series[p];
      segs.addAll([
        (' Tu día de mayor calma fue el ', false),
        (dayName(point.day), true),
        (' (${point.calm!.toStringAsFixed(1)}/10).', false),
      ]);
    }
    return segs;
  }

  /// Mensaje del recuadro inferior de la gráfica.
  String get stabilityMessage {
    final d = deltaPct(avgCalm, prevCalm);
    if (avgCalm == null) return 'Registra más días para ver tu evolución';
    if (d == null) return 'Aún no hay un periodo anterior con el que comparar';
    if (d >= 5) return 'Tu calma promedio va en aumento';
    if (d <= -5) return 'Tu calma promedio bajó respecto al periodo anterior';
    return 'Tu calma se mantiene estable';
  }

  /// Factores que más se relacionan con tu calma (mín. 2 registros por factor).
  List<Trigger> get triggers {
    final base = avgCalm;
    if (base == null || base == 0) return [];
    final byTag = <String, List<int>>{};
    for (final e in current) {
      final c = e.emotionIntensity;
      if (c == null) continue;
      for (final t in e.tags.toSet()) {
        byTag.putIfAbsent(t, () => []).add(c);
      }
    }
    final out = <Trigger>[];
    byTag.forEach((tag, v) {
      if (v.length < 2) return;
      final avg = v.reduce((a, b) => a + b) / v.length;
      final pct = ((avg - base) / base * 100).round();
      if (pct.abs() >= 8) out.add(Trigger(tag, pct, v.length));
    });
    out.sort((a, b) => b.impactPct.abs().compareTo(a.impactPct.abs()));
    return out.take(3).toList();
  }
}