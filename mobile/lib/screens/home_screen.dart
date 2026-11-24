import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

// Paleta de la pantalla de inicio (tomada del diseño en Figma)
class _C {
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
  static const track = Color(0xFFEDF3EE);
  static const green = Color(0xFF10B981);
  static const avatar = Color(0xFF4D6453);
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

  static const _moods = [
    ('🌿', 'En calma'),
    ('⚡', 'Con\nenergía'),
    ('☕', 'Cansado'),
    ('🍃', 'Ansioso'),
    ('🌧️', 'Sensible'),
  ];

  static const _days = [
    ('L', _Day.done),
    ('M', _Day.done),
    ('X', _Day.done),
    ('J', _Day.done),
    ('V', _Day.today),
    ('S', _Day.pending),
    ('D', _Day.pending),
  ];

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
      body: SingleChildScrollView(
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
              _navItem(Icons.menu_book_outlined, 'Diario'),
              _navItem(Icons.show_chart, 'Progreso'),
              _navItem(Icons.eco, 'Inicio', selected: true),
              _navItem(Icons.local_florist_outlined, 'Recursos'),
              _navItem(Icons.volunteer_activism_outlined, 'Ayuda'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, {bool selected = false}) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: selected ? null : _soon,
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
              child: Text('Semana 14 · Consistente',
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
              onTap: _soon,
              child: SizedBox(
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_circle_outline,
                        size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('+ Registro Completo & Diario',
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
        onTap: () => setState(() => _mood = i),
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
                          Text('Pulso de hoy', style: _head(16)),
                          Text('Sincronizado vía Apple Health ·\n09:42',
                              style: _body(11, h: 1.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
                      decoration: const BoxDecoration(
                          color: _C.green, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text('En rango\nóptimo',
                        style: _body(11, w: FontWeight.w700, c: _C.accent, h: 1.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _metric('Calma', Icons.spa_outlined, '8', '/10', 0.8, 'Alta estabilidad'),
              const SizedBox(width: 8),
              _metric('Energía', Icons.wb_sunny_outlined, '7', '/10', 0.7,
                  'Nivel óptimo'),
              const SizedBox(width: 8),
              _metric('Descanso', Icons.nightlight_outlined, '7.5', 'h', 0.75,
                  'Sueño profundo'),
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
                  child: Text('Tono autonómico estable para iniciar tu jornada',
                      style: _body(12, w: FontWeight.w500, c: _C.forest, h: 1.5)),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.check_circle_outline, size: 13, color: _C.muted),
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
            _bar(progress,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _C.forest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome,
                                size: 11, color: Colors.white),
                            const SizedBox(width: 4),
                            Text('Diagnóstico Preventivo IA',
                                style: _body(11,
                                    w: FontWeight.w700,
                                    c: Colors.white,
                                    ls: 0.275)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text('Certeza 94%',
                            overflow: TextOverflow.ellipsis,
                            style: _body(11, w: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.verified_outlined, size: 16, color: _C.accent),
              ],
            ),
          ),
          const SizedBox(height: 11),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Tienes 4 registros consistentes esta semana.',
                  style: _body(13.5, w: FontWeight.w700, c: _C.ink, h: 1.62),
                ),
                TextSpan(
                  text:
                      ' Tu sistema nervioso muestra mayor estabilidad biométrica al despertar.',
                  style: _body(13.5, c: _C.body, h: 1.62),
                ),
              ],
            ),
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
                const _PhotoPlaceholder(size: 48, icon: Icons.emoji_food_beverage_outlined),
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
                    onTap: _soon,
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
                    Text('Meta: 5 de 7 días completados', style: _body(12, h: 1.5)),
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
                    const Icon(Icons.bolt, size: 14, color: _C.accent),
                    const SizedBox(width: 4),
                    Text('340 pts',
                        style: _body(12, w: FontWeight.w700, c: _C.ink)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _bar(0.72, height: 10, fill: _C.forest, track: _C.track),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text('Lun · Mar · Mié · Jue (4/5)',
                    overflow: TextOverflow.ellipsis,
                    style: _body(11, w: FontWeight.w500)),
              ),
              const SizedBox(width: 8),
              Text('+50 pts al registrar hoy',
                  style: _body(11, w: FontWeight.w700, c: _C.ink)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < _days.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                _dayTile(_days[i].$1, _days[i].$2),
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