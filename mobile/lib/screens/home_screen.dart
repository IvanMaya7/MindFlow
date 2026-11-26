import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../data/auth_service.dart' show ApiException;
import '../data/journal_service.dart';
import '../data/journal_entry.dart';
import 'diary_screen.dart';
import 'progress_screen.dart';
import 'resources_screen.dart';
import 'help_screen.dart';

// Paleta de la pantalla de inicio (tomada del diseño en Figma)
class _C {
  static const bg = Color(0xFFF4EBDD);
  static const ink = Color(0xFF1A2421);
  static const muted = Color(0xFF566A60);
  static const muted2 = Color(0xFF556F60);
  static const forest = Color(0xFF1E3A2B);
  static const accent = Color(0xFF3B6E51);
  static const border = Color(0xFFD1E2D6);
  static const chip = Color(0xFFF1F7F2);
  static const mint = Color(0xFFE4F0E7);
  static const track = Color(0xFFEDF3EE);
  static const green = Color(0xFF10B981);
  static const avatar = Color(0xFF4D6453);
  static const body = Color(0xFF263B30);
}

TextStyle _head(double size,
        {FontWeight w = FontWeight.w800, Color c = _C.ink, double? ls, double? h}) =>
    GoogleFonts.nunitoSans(
        fontSize: size, fontWeight: w, color: c, letterSpacing: ls, height: h);

TextStyle _body(double size,
        {FontWeight w = FontWeight.w400, Color c = _C.muted, double? ls, double? h}) =>
    GoogleFonts.inter(
        fontSize: size, fontWeight: w, color: c, letterSpacing: ls, height: h);

enum _Day { done, today, pending }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _mood;

  final _journal = JournalService();
  bool _savingMood = false;

  JournalStats _stats = JournalStats([]);
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final entries = await _journal.listEntries();
      if (mounted) setState(() => _stats = JournalStats(entries));
    } on ApiException {
      // Si falla, el Inicio se queda con lo que tenía; no es motivo para un error en pantalla.
    } finally {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  // Claves que entiende el backend, en el mismo orden que los chips
  static const _moodKeys = ['calma', 'esperanzado', 'cansado', 'ansioso', 'triste'];

  bool get _limitReached => _stats.todayCount >= JournalStats.dailyLimit;

  void _showLimit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Llegaste al límite de 5 registros por hoy. Mañana puedes continuar.'),
      ),
    );
  }

  Future<void> _openDiary() async {
    if (_limitReached) {
      _showLimit();
      return;
    }

    // Si ya registró hoy, avisamos y preguntamos antes de abrir otro.
    final count = _stats.todayCount;
    if (count >= 1) {
      final goOn = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: _C.bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Ya registraste hoy', style: _head(18)),
          content: Text(
            count == 1
                ? 'Hoy ya escribiste un registro. ¿Quieres añadir otro?'
                : 'Hoy ya llevas $count de ${JournalStats.dailyLimit} registros. ¿Quieres añadir otro?',
            style: _body(14, c: _C.body, h: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Ahora no', style: _body(14, w: FontWeight.w600)),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(backgroundColor: _C.forest),
              child: Text('Sí, añadir otro',
                  style: _body(14, w: FontWeight.w700, c: Colors.white)),
            ),
          ],
        ),
      );
      if (goOn != true || !mounted) return;
    }

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const DiaryScreen()),
    );
    if (saved == true) _loadStats();
  }

  Future<void> _openProgress() async {
    final r = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => ProgressScreen(entries: _stats.entries)),
    );
    // Si en Progreso tocó otra pestaña, aquí la abrimos
    if (r == 'diary' && mounted) _openDiary();
    if (r == 'help' && mounted) _openHelp();
  }

  Future<void> _openHelp() async {
    final r = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const HelpScreen()),
    );
    if (!mounted) return;
    if (r == 'diary') _openDiary();
    if (r == 'progress') _openProgress();
  }

  Future<void> _openResources() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ResourcesScreen()),
    );
    if (mounted) _loadStats();
  }

  Future<void> _quickSave(int i) async {
    if (_savingMood) return;
    setState(() {
      _mood = i;
      _savingMood = true;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _journal.createEntry(primaryEmotion: _moodKeys[i]);
      messenger.showSnackBar(const SnackBar(content: Text('Emoción registrada')));
      _loadStats();
    } on ApiException catch (e) {
      if (mounted) setState(() => _mood = null);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _savingMood = false);
    }
  }

  static const _moods = [
    ('🌿', 'En calma'),
    ('⚡', 'Con\nenergía'),
    ('☕', 'Cansado'),
    ('🍃', 'Ansioso'),
    ('🌧️', 'Sensible'),
  ];

  static const _weekdayShort = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  static const _weekdayLetter = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  static const _emotionLabels = {
    'calma': 'En calma',
    'esperanzado': 'Esperanzado',
    'cansado': 'Cansado',
    'ansioso': 'Ansioso',
    'triste': 'Sensible',
    'agradecido': 'Agradecido',
  };

  String _when(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    final diff = today.difference(day).inDays;
    final label = diff == 0 ? 'hoy' : diff == 1 ? 'ayer' : '${d.day}/${d.month}';
    return '$label $hh:$mm';
  }

  void _soon() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Próximamente')));
  }

  void _openProfile() {
    final user = context.read<AuthProvider>().user;
    showModalBottomSheet(
      context: context,
      backgroundColor: _C.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user?.displayName ?? '', style: _head(18)),
              const SizedBox(height: 2),
              Text(user?.email ?? '', style: _body(13)),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout, color: _C.forest),
                title: Text('Cerrar sesión',
                    style: _body(14, w: FontWeight.w600, c: _C.forest)),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  context.read<AuthProvider>().logout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Pantalla ----------------

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final firstName = (user?.displayName ?? '').trim().split(' ').first;

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: _header(),
      bottomNavigationBar: _bottomNav(),
      body: RefreshIndicator(
        color: _C.forest,
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _greeting(firstName),
                  const SizedBox(height: 16),
                  _quickMood(),
                  const SizedBox(height: 16),
                  _pulse(),
                  const SizedBox(height: 16),
                  _insight(),
                  const SizedBox(height: 16),
                  _route(),
                  const SizedBox(height: 16),
                  _pause(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- Encabezado y navegación ----------------

  PreferredSizeWidget _header() {
    return AppBar(
      backgroundColor: _C.bg.withValues(alpha: 0.92),
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      toolbarHeight: 64,
      titleSpacing: 16,
      automaticallyImplyLeading: false,
      shape: Border(bottom: BorderSide(color: _C.border.withValues(alpha: 0.6))),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _C.forest,
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
                Text('MINDFLOW · BIOMETRÍA',
                    overflow: TextOverflow.ellipsis,
                    style: _body(10, w: FontWeight.w700, c: _C.muted2, ls: 1)),
                Text('Panel Diario', style: _head(16, c: _C.forest)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: _C.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration:
                    const BoxDecoration(color: _C.green, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text('Sincronizado',
                  style: _body(11, w: FontWeight.w600, c: _C.forest)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: _C.avatar,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _openProfile,
            child: const SizedBox(
              width: 32,
              height: 32,
              child: Icon(Icons.person_outline, size: 16, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _bottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: _C.bg.withValues(alpha: 0.95),
        border: const Border(top: BorderSide(color: _C.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.menu_book_outlined, 'Diario', onTap: _openDiary),
              _navItem(Icons.show_chart, 'Progreso', onTap: _openProgress),
              _navItem(Icons.eco, 'Inicio', selected: true),
              _navItem(Icons.local_florist_outlined, 'Recursos', onTap: _openResources),
              _navItem(Icons.volunteer_activism_outlined, 'Ayuda', onTap: _openHelp),
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
      onTap: selected ? null : (onTap ?? _soon),
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
                    decoration: const BoxDecoration(
                        color: _C.mint, shape: BoxShape.circle),
                    child: Icon(icon, size: 18, color: _C.forest),
                  )
                : Icon(icon, size: 21, color: _C.muted2),
            const SizedBox(height: 2),
            Text(
              label,
              style: _body(10,
                  w: selected ? FontWeight.w700 : FontWeight.w500,
                  c: selected ? _C.forest : _C.muted2),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Secciones ----------------

  Widget _greeting(String firstName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.monitor_heart_outlined, size: 14, color: _C.muted),
                const SizedBox(width: 6),
                Text('MONITOREO AUTÓNOMO',
                    style: _body(11, w: FontWeight.w700, ls: 0.55)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE2EDE5),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text('${_stats.daysThisWeek} de 7 días esta semana',
                  style: _body(12, w: FontWeight.w600, c: const Color(0xFF2E5941))),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          firstName.isEmpty
              ? 'Hola, un paso a la vez'
              : 'Hola $firstName, un paso a la vez',
          style: _head(26, ls: -0.65, h: 1.25),
        ),
        const SizedBox(height: 3),
        Text('Comprueba tu pulso y sincroniza tus hábitos de bienestar.',
            style: _body(13, h: 1.5)),
      ],
    );
  }

  Widget _quickMood() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    const Icon(Icons.sentiment_satisfied_alt_outlined,
                        size: 16, color: _C.forest),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text('¿Cómo te sientes justo ahora?',
                          overflow: TextOverflow.ellipsis,
                          style: _head(15, w: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('Toque rápido', style: _body(11, w: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < _moods.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                _moodChip(i),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Material(
            color: _C.forest,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _openDiary,
              child: SizedBox(
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_circle_outline,
                        size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Registro Completo & Diario',
                        style: _body(14, w: FontWeight.w700, c: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _moodChip(int i) {
    final selected = _mood == i;
    final (emoji, label) = _moods[i];
    return Expanded(
      child: GestureDetector(
        onTap: () => _quickSave(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 76,
          decoration: BoxDecoration(
            color: selected ? _C.mint : _C.chip,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? _C.accent : _C.border.withValues(alpha: 0.7),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: _body(11,
                    w: FontWeight.w600, c: _C.forest, ls: -0.275, h: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pulse() {
    final latest = _stats.latest;
    final calm = _stats.lastCalm;
    final energy = _stats.lastEnergy;
    final stress = _stats.lastStress;
    final sleep = _stats.lastSleep;

    String calmCap(int v) =>
        v >= 7 ? 'Alta estabilidad' : v >= 4 ? 'Ánimo variable' : 'Inquietud perceptible';
    String energyCap(int v) =>
        v >= 7 ? 'Plena vitalidad' : v >= 4 ? 'Energía moderada' : 'Fatiga baja';
    String sleepCap(int h) => h < 5
        ? 'Sueño insuficiente'
        : h < 7
            ? 'Sueño corto'
            : h <= 9
                ? 'Descanso reparador'
                : 'Sueño extenso';

    final stressColor = stress == null
        ? _C.green
        : stress <= 3
            ? _C.green
            : stress <= 6
                ? const Color(0xFFF59E0B)
                : const Color(0xFFDC2626);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _C.mint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.monitor_heart_outlined,
                          size: 15, color: _C.accent),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tu pulso emocional', style: _head(16)),
                          Text(
                            latest == null
                                ? (_loadingStats ? 'Cargando…' : 'Aún sin registros')
                                : 'Último registro · ${_when(latest.createdAt)}',
                            style: _body(11, h: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (stress != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: _C.chip,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: _C.border.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration:
                            BoxDecoration(color: stressColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Text('Estrés\n$stress/10',
                          style: _body(11, w: FontWeight.w700, c: _C.accent, h: 1.5)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _metric('Calma', Icons.spa_outlined, calm?.toString() ?? '–', '/10',
                  (calm ?? 0) / 10, calm == null ? 'Sin datos' : calmCap(calm)),
              const SizedBox(width: 8),
              _metric('Energía', Icons.wb_sunny_outlined, energy?.toString() ?? '–',
                  '/10', (energy ?? 0) / 10,
                  energy == null ? 'Sin datos' : energyCap(energy)),
              const SizedBox(width: 8),
              _metric('Descanso', Icons.nightlight_outlined, sleep?.toString() ?? '–',
                  'h', (sleep ?? 0) / 12, sleep == null ? 'Sin datos' : sleepCap(sleep)),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: _C.mint.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Icon(Icons.spa_outlined, size: 14, color: _C.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    latest == null
                        ? 'Registra cómo te sientes para ver tu pulso'
                        : 'Tu último estado: ${_emotionLabels[latest.primaryEmotion] ?? latest.primaryEmotion}',
                    style: _body(12, w: FontWeight.w500, c: _C.forest, h: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, IconData icon, String value, String unit,
      double progress, String caption) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: _C.chip,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.border.withValues(alpha: 0.7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: _body(11, w: FontWeight.w600)),
                ),
                Icon(icon, size: 13, color: _C.accent),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: _head(20)),
                const SizedBox(width: 2),
                Text(unit, style: _body(11, w: FontWeight.w500, c: _C.muted2)),
              ],
            ),
            const SizedBox(height: 8),
            _bar(progress.clamp(0.0, 1.0),
                height: 6, fill: _C.accent, track: _C.border.withValues(alpha: 0.6)),
            const SizedBox(height: 8),
            Text(caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _body(10, c: _C.muted2)),
          ],
        ),
      ),
    );
  }

  Widget _bar(double value,
      {required double height, required Color fill, required Color track}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: Stack(
        children: [
          Container(height: height, color: track),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value,
            child: Container(height: height, color: fill),
          ),
        ],
      ),
    );
  }

  Widget _insight() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 11),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE3EDE6))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _C.forest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.insights, size: 11, color: Colors.white),
                      const SizedBox(width: 4),
                      Text('Observación de tu semana',
                          style: _body(11,
                              w: FontWeight.w700, c: Colors.white, ls: 0.275)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 11),
          Text(
            _loadingStats
                ? 'Cargando tus registros…'
                : (_stats.insight ??
                    'Aún no tienes registros. Toca una emoción arriba para empezar.'),
            style: _body(13.5, w: FontWeight.w600, c: _C.ink, h: 1.62),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: _C.chip,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.border.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                const _PhotoPlaceholder(
                    size: 48, icon: Icons.emoji_food_beverage_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RECOMENDACIÓN ACTIVA',
                          style: _body(11,
                              w: FontWeight.w700, c: _C.accent, ls: 0.55)),
                      Text('Infusión tibia & luz natural 10 min',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _head(13, w: FontWeight.w700)),
                      Text('Prolonga la ventana de alerta sin elevar cortisol.',
                          style: _body(11, h: 1.5)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Material(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: _C.border),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _openDiary,
                    child: const SizedBox(
                      width: 32,
                      height: 32,
                      child: Icon(Icons.arrow_forward, size: 14, color: _C.forest),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _route() {
    final week = _stats.week;
    final done = _stats.daysThisWeek;
    final todayDone = week.last.emotion != null;
    final doneNames = [
      for (final d in week)
        if (d.emotion != null) _weekdayShort[d.day.weekday - 1],
    ];
    final streak = _stats.streak;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ruta de Bienestar Semanal', style: _head(15)),
                    Text('$done de 7 días registrados', style: _body(12, h: 1.5)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                  color: _C.mint,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: const Color(0x6688B797)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department_outlined,
                        size: 14, color: _C.accent),
                    const SizedBox(width: 4),
                    Text(streak == 1 ? '1 día de racha' : '$streak días de racha',
                        style: _body(12, w: FontWeight.w700, c: _C.ink)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _bar(done / 7, height: 10, fill: _C.forest, track: _C.track),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  doneNames.isEmpty
                      ? 'Aún sin registros esta semana'
                      : doneNames.join(' · '),
                  overflow: TextOverflow.ellipsis,
                  style: _body(11, w: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              Text(todayDone ? 'Hoy ya registraste' : 'Falta registrar hoy',
                  style: _body(11, w: FontWeight.w700, c: _C.ink)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < week.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                _dayTile(
                  _weekdayLetter[week[i].day.weekday - 1],
                  week[i].emotion != null
                      ? _Day.done
                      : (i == week.length - 1 ? _Day.today : _Day.pending),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _dayTile(String letter, _Day state) {
    late final Color bg;
    Border? border;
    late final Widget content;

    switch (state) {
      case _Day.done:
        bg = _C.forest;
        content = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(letter, style: _body(11, w: FontWeight.w700, c: Colors.white)),
            const SizedBox(height: 4),
            const Icon(Icons.check, size: 10, color: Colors.white),
          ],
        );
      case _Day.today:
        bg = _C.mint;
        border = Border.all(color: _C.accent);
        content = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(letter, style: _body(11, w: FontWeight.w700, c: _C.forest)),
            const SizedBox(height: 6),
            Container(
              width: 6,
              height: 6,
              decoration:
                  const BoxDecoration(color: _C.forest, shape: BoxShape.circle),
            ),
          ],
        );
      case _Day.pending:
        bg = _C.track;
        content = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(letter, style: _body(11, w: FontWeight.w500)),
            const SizedBox(height: 2),
            Text('-', style: _body(10, w: FontWeight.w500)),
          ],
        );
    }

    return Expanded(
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: border,
        ),
        child: content,
      ),
    );
  }

  Widget _pause() {
    return _Card(
      radius: 12,
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          const _PhotoPlaceholder(size: 40, icon: Icons.spa_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Micro-pausa de 3 minutos', style: _head(13, w: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Respiración diafragmática para regular el pulso.',
                    style: _body(11, h: 1.5)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: _C.forest,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _soon,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text('Iniciar',
                    style: _body(12, w: FontWeight.w700, c: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- Widgets auxiliares ----------------

class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    this.padding = const EdgeInsets.all(17),
    this.radius = 16,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _C.border),
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

/// Marcador de posición para las fotos del diseño (se reemplaza por la imagen real).
class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({required this.size, required this.icon});

  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _C.mint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: size * 0.5, color: _C.accent),
    );
  }
}