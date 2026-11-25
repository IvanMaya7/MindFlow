import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/auth_service.dart' show ApiException;
import '../data/journal_service.dart';

// Paleta del diario (tomada del diseño en Figma)
class _D {
  static const bg = Color(0xFFF4EBDD);
  static const ink = Color(0xFF1F1B13);
  static const muted = Color(0xFF424843);
  static const primary = Color(0xFF3E5F4D);
  static const cream = Color(0xFFFCF2E4);
  static const cream2 = Color(0xFFF6EDDF);
  static const dot = Color(0xFFAFC8B4);
  static const sand = Color(0xFFD8C7A6);
  static const mint = Color(0xFFC3E8D1);
  static const mintInk = Color(0xFF486A57);
  static const neutral = Color(0xFFF0E7D9);
  static const gray = Color(0xFFC3C8C1);
}

TextStyle _h(double size,
        {FontWeight w = FontWeight.w600, Color c = _D.ink, double? ls, double? h}) =>
    GoogleFonts.nunitoSans(
        fontSize: size, fontWeight: w, color: c, letterSpacing: ls, height: h);

TextStyle _t(double size,
        {FontWeight w = FontWeight.w400, Color c = _D.muted, double? ls, double? h}) =>
    GoogleFonts.inter(
        fontSize: size, fontWeight: w, color: c, letterSpacing: ls, height: h);

// ---------------- Opciones (la clave es lo que se guarda en la base) ----------------

class _Emotion {
  const _Emotion(this.key, this.title, this.subtitle, this.icon);
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
}

const _emotions = <_Emotion>[
  _Emotion('calma', 'En calma', 'Sereno y equilibrado', Icons.eco_outlined),
  _Emotion('esperanzado', 'Esperanzado', 'Vitalidad y propósito', Icons.wb_sunny_outlined),
  _Emotion('cansado', 'Cansado', 'Baja batería mental', Icons.bedtime_outlined),
  _Emotion('ansioso', 'Ansioso', 'Mente acelerada', Icons.air),
  _Emotion('triste', 'Triste / Sensible', 'Vulnerabilidad tierna', Icons.water_drop_outlined),
  _Emotion('agradecido', 'Agradecido', 'Afecto y armonía', Icons.favorite_border),
];

class _Opt {
  const _Opt(this.key, this.label);
  final String key;
  final String label;
}

const _sensations = <_Opt>[
  _Opt('ligero', 'Ligero'),
  _Opt('tension_hombros', 'Tensión en hombros'),
  _Opt('respiracion_tranquila', 'Respiración tranquila'),
  _Opt('inquietud', 'Inquietud'),
  _Opt('pecho_oprimido', 'Pecho oprimido'),
];

const _tagOptions = <_Opt>[
  _Opt('trabajo', '#Trabajo'),
  _Opt('familia', '#Familia'),
  _Opt('descanso', '#Descanso'),
  _Opt('salud', '#Salud'),
  _Opt('vinculos', '#Vínculos'),
  _Opt('clima', '#Clima'),
  _Opt('alimentacion', '#Alimentación'),
  _Opt('estudios', '#Estudios'),
];

const _months = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];

const _stepTitles = [
  'Paso 1 De 3 Estado Actual',
  'Paso 2 De 3 Desencadenantes',
  'Paso 3 De 3 Reflexión Y Cierre',
];

// Etiqueta y colores de la píldora según el valor del slider
(String, Color, Color) _calmBadge(int v) => v <= 3
    ? ('Inquietud perceptible', _D.sand, _D.muted)
    : v <= 6
        ? ('Ánimo variable', _D.neutral, _D.ink)
        : ('Calma estable', _D.mint, _D.mintInk);

(String, Color, Color) _energyBadge(int v) => v <= 3
    ? ('Fatiga baja', _D.sand, _D.muted)
    : v <= 6
        ? ('Energía moderada', _D.neutral, _D.ink)
        : ('Plena vitalidad', _D.mint, _D.mintInk);

(String, Color, Color) _stressBadge(int v) => v <= 3
    ? ('Bajo / Manejable', _D.mint, _D.mintInk)
    : v <= 6
        ? ('Tensión moderada', _D.neutral, _D.ink)
        : ('Sobrecarga alta', _D.sand, _D.muted);

(String, Color, Color) _sleepBadge(int h) => h < 5
    ? ('Sueño insuficiente', _D.neutral, _D.ink)
    : h < 7
        ? ('Sueño corto', _D.sand, _D.muted)
        : h <= 9
            ? ('Descanso reparador', _D.mint, _D.mintInk)
            : ('Sueño extenso', _D.neutral, _D.ink);

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final _service = JournalService();
  final _scroll = ScrollController();
  final _notes = TextEditingController();

  int _step = 0;
  String? _emotion;
  bool _emotionError = false;
  bool _sensError = false;
  bool _metricsError = false;
  bool _tagError = false;
  bool _notesError = false;
  final Set<String> _sens = {};
  final Set<String> _tagSel = {};

  int _calm = 1, _energy = 1, _stress = 1, _sleep = 3;
  bool _calmT = false, _energyT = false, _stressT = false, _sleepT = false;

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _scroll.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    setState(() {
      _step = step;
      _error = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _nextFromEmotion() {
    setState(() {
      _emotionError = _emotion == null;
      _sensError = _sens.isEmpty;
    });
    if (_emotion == null || _sens.isEmpty) return;
    _goTo(1);
  }

    void _nextFromMetrics() {
    final ok = _calmT && _energyT && _stressT && _sleepT;
    setState(() => _metricsError = !ok);
    if (ok) _goTo(2);
  }

  String _today() {
    final d = DateTime.now();
    return '${d.day} de ${_months[d.month - 1]}';
  }

  Future<void> _save() async {
    final notes = _notes.text.trim();
    final tagsOk = _tagSel.isNotEmpty;
    final notesOk = notes.isNotEmpty;
    if (!tagsOk || !notesOk) {
      setState(() {
        _tagError = !tagsOk;
        _notesError = !notesOk;
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _service.createEntry(
        primaryEmotion: _emotion!,
        bodySensations:
            _sensations.where((o) => _sens.contains(o.key)).map((o) => o.key).toList(),
        emotionIntensity: _calmT ? _calm : null,
        energyLevel: _energyT ? _energy : null,
        stressLevel: _stressT ? _stress : null,
        sleepQuality: _sleepT ? _sleep : null,
        tags: _tagOptions.where((o) => _tagSel.contains(o.key)).map((o) => o.key).toList(),
        textNotes: notes.isEmpty ? null : notes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro guardado. Gracias por escucharte hoy.')),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---------------- Pantalla ----------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo(_step - 1);
      },
      child: Scaffold(
        backgroundColor: _D.bg,
        appBar: _header(),
        body: SingleChildScrollView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _progress(),
                  const SizedBox(height: 20),
                  if (_step == 0)
                    ..._stepEmotion()
                  else if (_step == 1)
                    ..._stepMetrics()
                  else
                    ..._stepReflection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _header() {
    return AppBar(
      backgroundColor: _D.bg.withValues(alpha: 0.8),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 64,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, size: 22, color: _D.ink),
        onPressed: _saving
            ? null
            : () {
                if (_step == 0) {
                  Navigator.of(context).pop();
                } else {
                  _goTo(_step - 1);
                }
              },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Diario Emocional', style: _h(18)),
          Text(_stepTitles[_step], style: _t(11, w: FontWeight.w500, ls: 0.22)),
        ],
      ),
    );
  }

  Widget _progress() {
    const labels = [
      'Paso 1 de 3 • Sensaciones y emoción',
      'Paso 2 de 3: Métricas Dinámicas',
      'Paso 3 de 3: Actores y Reflexión final',
    ];
    const percents = ['33%', '66% completado', '100%'];

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    if (_step > 0) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: _D.primary, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        labels[_step],
                        overflow: TextOverflow.ellipsis,
                        style: _t(13, w: FontWeight.w600, c: _D.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(percents[_step],
                  style: _t(11,
                      w: FontWeight.w600,
                      c: _D.primary.withValues(alpha: 0.8),
                      ls: 0.22)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Stack(
              children: [
                Container(height: 8, color: _D.cream2),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (_step + 1) / 3,
                  child: Container(height: 8, color: _D.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Paso 1: emoción y cuerpo ----------------

  List<Widget> _stepEmotion() {
    return [
      _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.spa_outlined, size: 15, color: _D.primary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text('Tómate una pausa • Hoy, ${_today()}',
                      style: _t(13, w: FontWeight.w500, c: _D.primary)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('¿Cómo describirías tu estado emocional predominante hoy?',
                style: _h(18, h: 1.4)),
            const SizedBox(height: 8),
            Text('Selecciona la opción que resuene más con este instante de tu día.',
                style: _t(13, h: 1.55)),
            const SizedBox(height: 24),
            _emotionGrid(),
            if (_emotionError)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text('Elige una emoción para continuar',
                    style: _t(12, c: Theme.of(context).colorScheme.error)),
              ),
            const SizedBox(height: 24),
            _sensationsSection(),
            const SizedBox(height: 24),
            _noteBox(
              Icons.verified_user_outlined,
              'No hay emociones correctas ni incorrectas. Toda emoción es válida y '
              'merece ser escuchada.',
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      _primaryButton('Continuar a métricas (Paso 2)',
          icon: Icons.arrow_forward, onTap: _nextFromEmotion),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 12, color: _D.muted),
          const SizedBox(width: 6),
          Flexible(
            child: Text('Tu registro es completamente privado y confidencial',
                textAlign: TextAlign.center,
                style: _t(11, w: FontWeight.w500, ls: 0.22)),
          ),
        ],
      ),
    ];
  }

  Widget _emotionGrid() {
    return Column(
      children: [
        for (var i = 0; i < _emotions.length; i += 2)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _emotionCard(_emotions[i])),
                  const SizedBox(width: 12),
                  Expanded(child: _emotionCard(_emotions[i + 1])),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _emotionCard(_Emotion e) {
    final selected = _emotion == e.key;
    return GestureDetector(
      onTap: () => setState(() {
        _emotion = e.key;
        _emotionError = false;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? _D.cream2 : _D.cream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _D.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected ? Colors.white : _D.cream2,
                shape: BoxShape.circle,
              ),
              child: Icon(e.icon, size: 19, color: _D.primary),
            ),
            const SizedBox(height: 9),
            Text(e.title, style: _t(15, w: FontWeight.w600, c: _D.ink)),
            const SizedBox(height: 4),
            Text(e.subtitle, style: _t(12, h: 1.3)),
          ],
        ),
      ),
    );
  }

  Widget _sensationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                children: [
                  const Icon(Icons.accessibility_new_outlined, size: 16, color: _D.primary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text('Sensación en el cuerpo',
                        style: _t(15, w: FontWeight.w600, c: _D.ink)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text('Obligatorio', style: _t(11, w: FontWeight.w500, ls: 0.22)),
          ],
        ),
        const SizedBox(height: 10),
        Text('Tu cuerpo suele manifestar lo que la mente procesa en silencio.',
            style: _t(13, h: 1.55)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in _sensations)
              _pill(o.label,
                  selected: _sens.contains(o.key),
                  dot: true,
                  onTap: () => setState(() {
                    _sens.contains(o.key) ? _sens.remove(o.key) : _sens.add(o.key);
                    _sensError = false;
                  })),
          ],
        ),
        if (_sensError)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text('Elige al menos una sensación para continuar',
                style: _t(12, c: Theme.of(context).colorScheme.error)),
          ),
      ],
    );
  }

  // ---------------- Paso 2: métricas ----------------

  List<Widget> _stepMetrics() {
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.tune, size: 18, color: _D.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Sintoniza con tu ritmo interno',
                style: _h(26, ls: -0.65, h: 1.3)),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        'Evalúa cómo se siente tu energía, estrés y descanso en una escala del 1 al 10. '
        'Tómate una respiración y observa tu estado actual.',
        style: _t(15, h: 1.6),
      ),
      const SizedBox(height: 24),
      _metricCard(
        icon: Icons.spa_outlined,
        title: 'Calma & Estabilidad',
        subtitle: 'Sensación de arraigo y serenidad',
        value: _calm,
        touched: _calmT,
        min: 1,
        max: 10,
        unit: '/10',
        badge: _calmBadge(_calm),
        minLabel: '1: Agitación intensa',
        maxLabel: '10: Paz absoluta',
        minDot: _D.gray,
        maxDot: _D.primary,
        onChanged: (v) => setState(() {
          _calm = v;
          _calmT = true;
        }),
      ),
      const SizedBox(height: 16),
      _metricCard(
        icon: Icons.wb_sunny_outlined,
        title: 'Nivel de Energía',
        subtitle: 'Disposición física y vitalidad',
        value: _energy,
        touched: _energyT,
        min: 1,
        max: 10,
        unit: '/10',
        badge: _energyBadge(_energy),
        minLabel: '1: Sin fuerzas',
        maxLabel: '10: Plena vitalidad',
        minDot: _D.gray,
        maxDot: _D.primary,
        onChanged: (v) => setState(() {
          _energy = v;
          _energyT = true;
        }),
      ),
      const SizedBox(height: 16),
      _metricCard(
        icon: Icons.psychology_outlined,
        title: 'Estrés o Presión Mental',
        subtitle: 'Carga cognitiva acumulada',
        value: _stress,
        touched: _stressT,
        min: 1,
        max: 10,
        unit: '/10',
        badge: _stressBadge(_stress),
        minLabel: '1: Cero tensión',
        maxLabel: '10: Sobrecarga',
        minDot: _D.primary,
        maxDot: _D.gray,
        onChanged: (v) => setState(() {
          _stress = v;
          _stressT = true;
        }),
      ),
      const SizedBox(height: 16),
      _metricCard(
        icon: Icons.bedtime_outlined,
        title: 'Sueño & Descanso',
        subtitle: 'Calidad del reposo nocturno',
        value: _sleep,
        touched: _sleepT,
        min: 3,
        max: 12,
        unit: ' hrs',
        badge: _sleepBadge(_sleep),
        minLabel: '3 hrs (Insuficiente)',
        maxLabel: '12 hrs (Extenso)',
        onChanged: (v) => setState(() {
          _sleep = v;
          _sleepT = true;
        }),
      ),
      const SizedBox(height: 24),
        if (_metricsError && !(_calmT && _energyT && _stressT && _sleepT))
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text('Mueve cada control para indicar cómo te sientes',
              textAlign: TextAlign.center,
              style: _t(13, c: Theme.of(context).colorScheme.error)),
        ),
      _primaryButton('Continuar a reflexión (Paso 3)',
          icon: Icons.arrow_forward, onTap: _nextFromMetrics),
      const SizedBox(height: 8),
      Center(
        child: TextButton.icon(
          onPressed: () => _goTo(0),
          icon: const Icon(Icons.arrow_back, size: 14),
          label: Text('Volver al paso 1 (Emociones principales)',
              style: _t(13, w: FontWeight.w500)),
          style: TextButton.styleFrom(foregroundColor: _D.muted),
        ),
      ),
    ];
  }

  Widget _metricCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required int value,
    required bool touched,
    required int min,
    required int max,
    required String unit,
    required (String, Color, Color) badge,
    required String minLabel,
    required String maxLabel,
    Color? minDot,
    Color? maxDot,
    required ValueChanged<int> onChanged,
  }) {
    final (badgeText, badgeBg, badgeFg) = badge;

    return _card(
      error: _metricsError && !touched,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration:
                    const BoxDecoration(color: _D.cream, shape: BoxShape.circle),
                child: Icon(icon, size: 18, color: _D.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: _h(18, h: 1.3)),
                    Text(subtitle, style: _t(13, h: 1.5)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$value',
                          style: _h(22, w: FontWeight.w700, c: _D.primary, ls: -0.55)),
                      Text(unit, style: _h(14, c: _D.muted)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(badgeText,
                        textAlign: TextAlign.center,
                        style: _t(11, w: FontWeight.w500, c: badgeFg, ls: 0.22)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 8,
              activeTrackColor: _D.primary,
              inactiveTrackColor: _D.cream2,
              thumbColor: touched ? _D.primary : _D.sand,
              overlayColor: _D.primary.withValues(alpha: 0.12),
              trackShape: const RoundedRectSliderTrackShape(),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              tickMarkShape: SliderTickMarkShape.noTickMark,
              showValueIndicator: ShowValueIndicator.never,
            ),
            child: Slider(
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: max - min,
              value: value.toDouble(),
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      if (minDot != null) ...[_dot(minDot), const SizedBox(width: 4)],
                      Flexible(
                        child: Text(minLabel,
                            style: _t(11, w: FontWeight.w500, ls: 0.22)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(maxLabel,
                            textAlign: TextAlign.right,
                            style: _t(11, w: FontWeight.w500, ls: 0.22)),
                      ),
                      if (maxDot != null) ...[const SizedBox(width: 4), _dot(maxDot)],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  // ---------------- Paso 3: factores y reflexión ----------------

  List<Widget> _stepReflection() {
    final count = _tagSel.length;
    return [
      Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _D.dot.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.eco, size: 13, color: _D.primary),
              const SizedBox(width: 6),
              Text('Cierre reflexivo',
                  style: _t(11, w: FontWeight.w500, c: _D.primary, ls: 0.22)),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      Text('Tu espacio seguro de desahogo',
          style: _h(26, w: FontWeight.w700, c: const Color(0xFF1A2421), ls: -0.65, h: 1.3)),
      const SizedBox(height: 8),
      Text('¿Qué situaciones o pensamientos acompañaron tu jornada?',
          style: _t(15, h: 1.6)),
      const SizedBox(height: 24),
      _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCFE9D4).withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.sell_outlined,
                            size: 15, color: _D.primary),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text('Factores asociados a tu día',
                            style: _h(18, c: const Color(0xFF1A2421), h: 1.4)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  count == 1 ? '1\nseleccionado' : '$count\nseleccionados',
                  textAlign: TextAlign.right,
                  style: _t(11,
                      w: FontWeight.w500,
                      c: _D.primary.withValues(alpha: 0.7),
                      ls: 0.22),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _tagGrid(),
            if (_tagError)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text('Elige al menos un factor',
                    style: _t(12, c: Theme.of(context).colorScheme.error)),
              ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _noteBox(
              Icons.lightbulb_outline,
              '¿Qué situaciones, conversaciones o pensamientos marcaron tu día? '
              'Puedes escribir con total libertad, sin filtros ni juicios.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notes,
              minLines: 4,
              maxLines: 8,
              maxLength: 500,
              onChanged: (v) {
                if (_notesError && v.trim().isNotEmpty) {
                  setState(() => _notesError = false);
                }
              },
              textCapitalization: TextCapitalization.sentences,
              style: _t(15, c: _D.ink, h: 1.6),
              decoration: InputDecoration(
                hintText: '¿Cómo ha estado tu día?',
                hintStyle: _t(15, h: 1.6),
                counterText: '',
                errorText: _notesError ? 'Escribe algo para guardar tu registro' : null,                
                filled: true,
                fillColor: _D.cream,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _D.primary, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      // Texto honesto: el análisis con IA todavía no existe.
      // Cuando esté listo, el texto original del diseño era: "Tu entrada será analizada
      // de forma privada, encriptada y segura por nuestra IA para brindarte patrones de
      // bienestar, detectar señales de alerta y ofrecerte contención continua."
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _D.mint.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                  color: Color(0xFFCFE9D4), shape: BoxShape.circle),
              child: const Icon(Icons.shield_outlined, size: 17, color: _D.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Espacio protegido y confidencial',
                      style: _t(15, w: FontWeight.w600, c: _D.primary)),
                  const SizedBox(height: 1),
                  Text(
                    'Tu registro se guarda en tu cuenta y solo tú puedes consultarlo '
                    'desde la app.',
                    style: _t(13, h: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(_error!,
              textAlign: TextAlign.center,
              style: _t(13, c: Theme.of(context).colorScheme.error)),
        ),
      _primaryButton('Guardar registro',
          icon: Icons.spa, iconFirst: true, loading: _saving, onTap: _save),
      const SizedBox(height: 8),
      Center(
        child: TextButton.icon(
          onPressed: _saving ? null : () => _goTo(1),
          icon: const Icon(Icons.arrow_back, size: 14),
          label: Text('Volver a métricas', style: _t(13, w: FontWeight.w500)),
          style: TextButton.styleFrom(foregroundColor: _D.muted),
        ),
      ),
    ];
  }

  Widget _tagGrid() {
    return Column(
      children: [
        for (var i = 0; i < _tagOptions.length; i += 2)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
            child: Row(
              children: [
                Expanded(child: _tagPill(_tagOptions[i])),
                const SizedBox(width: 12),
                Expanded(
                  child: i + 1 < _tagOptions.length
                      ? _tagPill(_tagOptions[i + 1])
                      : const SizedBox(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _tagPill(_Opt o) => _pill(
        o.label,
        selected: _tagSel.contains(o.key),
        size: 14,
        w: FontWeight.w600,
        onTap: () => setState(() {
          _tagSel.contains(o.key) ? _tagSel.remove(o.key) : _tagSel.add(o.key);
          _tagError = false;
        }),
      );

  // ---------------- Piezas comunes ----------------

  Widget _card(Widget child, {bool error = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: error
            ? Border.all(color: Theme.of(context).colorScheme.error, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: _D.primary.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _noteBox(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _D.cream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration:
                const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: _D.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(text, style: _t(13, h: 1.6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(
    String label, {
    required bool selected,
    required VoidCallback onTap,
    bool dot = false,
    FontWeight w = FontWeight.w500,
    double size = 13,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _D.primary : _D.cream,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot) ...[
              _dot(selected ? _D.mint : _D.dot),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                style: _t(size, w: w, c: selected ? Colors.white : _D.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _primaryButton(
    String label, {
    required VoidCallback? onTap,
    IconData? icon,
    bool iconFirst = false,
    bool loading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _D.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: _D.primary,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: loading ? null : onTap,
          child: SizedBox(
            height: 54,
            child: Center(
              child: loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: _D.bg),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null && iconFirst) ...[
                          Icon(icon, size: 17, color: _D.bg),
                          const SizedBox(width: 10),
                        ],
                        Text(label, style: _t(15, w: FontWeight.w600, c: _D.bg)),
                        if (icon != null && !iconFirst) ...[
                          const SizedBox(width: 8),
                          Icon(icon, size: 15, color: _D.bg),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}