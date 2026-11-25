class JournalEntry {
  JournalEntry({
    required this.id,
    required this.createdAt,
    required this.primaryEmotion,
    this.emotionIntensity,
    this.energyLevel,
    this.stressLevel,
    this.sleepHours,
    this.tags = const [],
    this.textNotes,
  });

  final String id;
  final DateTime createdAt; // ya en hora local del teléfono
  final String primaryEmotion;
  final int? emotionIntensity; // calma 1-10
  final int? energyLevel; // 1-10
  final int? stressLevel; // 1-10
  final int? sleepHours; // en la base se guarda en sleepQuality
  final List<String> tags;
  final String? textNotes;

  factory JournalEntry.fromJson(Map<String, dynamic> j) => JournalEntry(
        id: j['id'].toString(),
        createdAt: DateTime.parse(j['createdAt'] as String).toLocal(),
        primaryEmotion: (j['primaryEmotion'] ?? '').toString(),
        emotionIntensity: j['emotionIntensity'] as int?,
        energyLevel: j['energyLevel'] as int?,
        stressLevel: j['stressLevel'] as int?,
        sleepHours: j['sleepQuality'] as int?,
        tags: (j['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
        textNotes: j['textNotes'] as String?,
      );
}

/// Cálculos del Inicio a partir de la lista (viene ordenada de más nueva a más vieja).
class JournalStats {
  JournalStats(this.entries);
  final List<JournalEntry> entries;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  bool get isEmpty => entries.isEmpty;

    static const dailyLimit = 5;

  /// Cuántos registros hizo hoy (hora del teléfono).
  int get todayCount {
    final t = _day(DateTime.now());
    return entries.where((e) => _day(e.createdAt) == t).length;
  }

  JournalEntry? get latest => entries.isEmpty ? null : entries.first;

  /// Último registro que SÍ trae ese dato (el rápido del Inicio solo trae emoción).
  int? get lastCalm => _lastOf((e) => e.emotionIntensity);
  int? get lastEnergy => _lastOf((e) => e.energyLevel);
  int? get lastStress => _lastOf((e) => e.stressLevel);
  int? get lastSleep => _lastOf((e) => e.sleepHours);

  int? _lastOf(int? Function(JournalEntry) pick) {
    for (final e in entries) {
      final v = pick(e);
      if (v != null) return v;
    }
    return null;
  }

  /// Últimos 7 días (de hace 6 días a hoy). Cada posición trae la emoción
  /// del registro más reciente de ese día, o null si no hubo.
  List<({DateTime day, String? emotion})> get week {
    final today = _day(DateTime.now());
    return List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      String? emotion;
      for (final e in entries) {
        if (_day(e.createdAt) == day) {
          emotion = e.primaryEmotion;
          break;
        }
      }
      return (day: day, emotion: emotion);
    });
  }

  int get daysThisWeek => week.where((d) => d.emotion != null).length;

  /// Días seguidos con al menos un registro. Si hoy aún no hay,
  /// la racha sigue viva desde ayer.
  int get streak {
    final days = entries.map((e) => _day(e.createdAt)).toSet();
    var cursor = _day(DateTime.now());
    if (!days.contains(cursor)) cursor = cursor.subtract(const Duration(days: 1));
    var n = 0;
    while (days.contains(cursor)) {
      n++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return n;
  }

  /// Promedio de un dato entre dos fechas [from, to).
  double? _avg(int? Function(JournalEntry) pick, DateTime from, DateTime to) {
    final vals = entries
        .where((e) => !e.createdAt.isBefore(from) && e.createdAt.isBefore(to))
        .map(pick)
        .whereType<int>()
        .toList();
    if (vals.isEmpty) return null;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  /// Texto de "observación" calculado con tus datos. No es IA: son reglas simples.
  String? get insight {
    if (entries.isEmpty) return null;
    final now = DateTime.now();
    final thisWeek = _avg((e) => e.stressLevel, now.subtract(const Duration(days: 7)), now);
    final prevWeek = _avg((e) => e.stressLevel, now.subtract(const Duration(days: 14)),
        now.subtract(const Duration(days: 7)));

    if (thisWeek != null && prevWeek != null) {
      final diff = thisWeek - prevWeek;
      if (diff <= -1) return 'Tu estrés promedio bajó esta semana respecto a la anterior. Buen ritmo.';
      if (diff >= 1) return 'Tu estrés promedio subió esta semana respecto a la anterior. Quizá te vendría bien una pausa.';
    }
    final sleep = lastSleep;
    if (sleep != null && sleep < 6) {
      return 'Dormiste pocas horas en tu último registro. Intenta descansar un poco más hoy.';
    }
    if (streak >= 3) return 'Llevas $streak días seguidos registrando cómo te sientes. Eso construye hábito.';
    return 'Cada registro cuenta. Con más días podremos mostrarte tendencias.';
  }
}