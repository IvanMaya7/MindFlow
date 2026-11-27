import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../data/resource.dart';
import '../data/resource_service.dart';
import '../providers/auth_provider.dart';
import 'diary_screen.dart';
import 'resource_detail_screen.dart';

// Paleta y tipografía tomadas de la pantalla de Inicio / Diario.
class _R {
  static const bg = Color(0xFFF4EBDD);
  static const ink = Color(0xFF1A2421);
  static const body = Color(0xFF263B30);
  static const muted = Color(0xFF566A60);
  static const muted2 = Color(0xFF556F60);
  static const forest = Color(0xFF1E3A2B);
  static const accent = Color(0xFF3B6E51);
  static const border = Color(0xFFD1E2D6);
  static const input = Color(0xFFF6ECDC);
  static const mint = Color(0xFFE4F0E7);
  static const green = Color(0xFF10B981);
  static const avatar = Color(0xFF4D6453);
}

TextStyle _head(double size,
        {FontWeight w = FontWeight.w800,
        Color c = _R.ink,
        double? ls,
        double? h}) =>
    GoogleFonts.nunitoSans(
        fontSize: size, fontWeight: w, color: c, letterSpacing: ls, height: h);

TextStyle _body(double size,
        {FontWeight w = FontWeight.w400,
        Color c = _R.muted,
        double? ls,
        double? h}) =>
    GoogleFonts.inter(
        fontSize: size, fontWeight: w, color: c, letterSpacing: ls, height: h);

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final _service = ResourceService();
  final _search = TextEditingController();

  List<Resource> _resources = const [];
  Set<String> _saved = <String>{};
  bool _loading = true;
  String _query = '';
  String _category = 'Todos';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool showSpinner = true}) async {
    if (showSpinner) setState(() => _loading = true);
    final resourcesFuture = _service.fetchResources();
    final savedFuture = _service.loadSavedIds();
    final resources = await resourcesFuture;
    final saved = await savedFuture;
    if (!mounted) return;
    setState(() {
      _resources = resources;
      _saved = saved;
      _loading = false;
    });
  }

  // ---------------- Derivados del catálogo ----------------

  Resource? get _recommended {
    for (final r in _resources) {
      if (r.featured && !r.isArticle) return r;
    }
    for (final kind in [
      ResourceKind.guide,
      ResourceKind.exercise,
      ResourceKind.audio,
    ]) {
      for (final r in _resources) {
        if (r.kind == kind) return r;
      }
    }
    return _resources.isEmpty ? null : _resources.first;
  }

  List<Resource> get _tools => _resources
      .where((r) => r.kind == ResourceKind.exercise || r.kind == ResourceKind.audio)
      .take(3)
      .toList();

  List<Resource> get _articles =>
      _resources.where((r) => r.isArticle).toList();

  List<String> get _categories {
    const preferred = [
      'Ansiedad & Pánico',
      'Respiración',
      'Sueño & Descanso',
      'Vínculos',
      'Estrés',
    ];
    final present = _resources.map((r) => r.category).toSet();
    return [
      'Todos',
      ...preferred.where(present.contains),
      ...present.where((c) => c != 'Todos' && !preferred.contains(c)),
    ];
  }

  List<Resource> get _filteredArticles {
    final q = _query.trim().toLowerCase();
    return _articles.where((r) {
      if (_category != 'Todos' && r.category != _category) return false;
      if (q.isEmpty) return true;
      final haystack = '${r.title} ${r.description} ${r.category} '
              '${r.author ?? ''} ${r.tags.join(' ')}'
          .toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  List<Resource> get _savedArticles =>
      _articles.where((r) => _saved.contains(r.id)).toList();

  // ---------------- Acciones ----------------

  void _openProgress() {
    Navigator.of(context).pop('progress');
  }

  void _openHelp() {
    Navigator.of(context).pop('help');
  }

  Future<void> _openDiary() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const DiaryScreen()),
    );
    if (mounted) _load(showSpinner: false);
  }

  void _goHome() {
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  Future<void> _toggleSaved(Resource r) async {
    final isSaved = _saved.contains(r.id);
    setState(() {
      if (isSaved) {
        _saved.remove(r.id);
      } else {
        _saved.add(r.id);
      }
    });
    await _service.saveSavedIds(_saved);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isSaved
            ? 'Artículo quitado de guardados'
            : 'Artículo guardado para leer después'),
      ),
    );
  }

  Future<void> _openDetail(Resource r) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResourceDetailScreen(
          resource: r,
          saved: _saved.contains(r.id),
          onSavedChanged: (value) async {
            if (!mounted) return;
            setState(() {
              if (value) {
                _saved.add(r.id);
              } else {
                _saved.remove(r.id);
              }
            });
            await _service.saveSavedIds(_saved);
          },
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  void _openProfile() {
    final user = context.read<AuthProvider>().user;
    showModalBottomSheet(
      context: context,
      backgroundColor: _R.bg,
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
                leading: const Icon(Icons.logout, color: _R.forest),
                title: Text('Cerrar sesión',
                    style: _body(14, w: FontWeight.w600, c: _R.forest)),
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

  void _showSaved() {
    final saved = _savedArticles;
    showModalBottomSheet(
      context: context,
      backgroundColor: _R.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _R.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.bookmark, size: 20, color: _R.forest),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Artículos guardados', style: _head(18)),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(sheetCtx).pop(),
                    icon: const Icon(Icons.close, size: 20, color: _R.muted),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                saved.isEmpty
                    ? 'Aún no has guardado artículos. Toca el marcador de una lectura para encontrarla aquí.'
                    : 'Tu espacio personal para volver a leer cuando lo necesites.',
                style: _body(13, h: 1.55),
              ),
              if (saved.isNotEmpty) ...[
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 420),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: saved.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final r = saved[i];
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            Navigator.of(sheetCtx).pop();
                            _openDetail(r);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: 52,
                                    height: 52,
                                    child: _RemoteImage(
                                      url: r.imageUrl,
                                      fallbackIcon: Icons.menu_book_outlined,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(r.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: _body(13,
                                              w: FontWeight.w700,
                                              c: _R.ink,
                                              h: 1.35)),
                                      const SizedBox(height: 2),
                                      Text(r.kindLabel, style: _body(11)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  tooltip: 'Quitar de guardados',
                                  onPressed: () {
                                    _toggleSaved(r);
                                    Navigator.of(sheetCtx).pop();
                                  },
                                  icon: const Icon(Icons.bookmark_remove_outlined,
                                      size: 19, color: _R.forest),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showHelp() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _R.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                        color: _R.mint, shape: BoxShape.circle),
                    child: const Icon(Icons.help_outline,
                        size: 20, color: _R.forest),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Ayuda urgente', style: _head(19)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'El Directorio & SOS conectará esta sección con profesionales de la '
                'salud mental y líneas de emergencia locales. Si estás en peligro '
                'inmediato, contacta a los servicios de emergencia de tu país.',
                style: _body(13, h: 1.6),
              ),
              const SizedBox(height: 16),
              _primaryButton('Entendido',
                  icon: Icons.check,
                  onTap: () => Navigator.of(sheetCtx).pop()),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Pantalla ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _R.bg,
      appBar: _header(),
      bottomNavigationBar: _bottomNav(),
      body: RefreshIndicator(
        color: _R.forest,
        onRefresh: () => _load(showSpinner: false),
        child: _loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 120),
                children: const [
                  Center(
                    child: CircularProgressIndicator(color: _R.forest),
                  ),
                ],
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _intro(),
                        const SizedBox(height: 18),
                        if (_recommended != null) ...[
                          _recommendedCard(_recommended!),
                          const SizedBox(height: 16),
                        ],
                        if (_tools.isNotEmpty) ...[
                          _quickToolsCard(),
                          const SizedBox(height: 16),
                        ],
                        _readingsCard(),
                        const SizedBox(height: 16),
                        _safetyCard(),
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
      backgroundColor: _R.bg.withValues(alpha: 0.92),
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      toolbarHeight: 64,
      titleSpacing: 16,
      automaticallyImplyLeading: false,
      shape: Border(bottom: BorderSide(color: _R.border.withValues(alpha: 0.6))),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _R.forest,
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
                    style: _body(10, w: FontWeight.w700, c: _R.muted2, ls: 1)),
                Text('Recursos', style: _head(16, c: _R.forest)),
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
            border: Border.all(color: _R.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration:
                    const BoxDecoration(color: _R.green, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text('Sincronizado',
                  style: _body(11, w: FontWeight.w600, c: _R.forest)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: _R.avatar,
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
        color: _R.bg.withValues(alpha: 0.95),
        border: const Border(top: BorderSide(color: _R.border)),
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
              _navItem(Icons.eco, 'Inicio', onTap: _goHome),
              _navItem(Icons.local_florist_outlined, 'Recursos', selected: true),
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
                    decoration: const BoxDecoration(
                        color: _R.mint, shape: BoxShape.circle),
                    child: Icon(icon, size: 18, color: _R.forest),
                  )
                : Icon(icon, size: 21, color: _R.muted2),
            const SizedBox(height: 2),
            Text(
              label,
              style: _body(10,
                  w: selected ? FontWeight.w700 : FontWeight.w500,
                  c: selected ? _R.forest : _R.muted2),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Secciones ----------------

  Widget _intro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(Icons.menu_book, size: 15, color: _R.ink),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text('BIBLIOTECA PSICOEDUCATIVA & AUTOCUIDADO',
                  style: _body(11, w: FontWeight.w800, c: _R.ink, ls: 0.45)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Recursos & Psicoeducación',
            style: _head(26, ls: -0.65, h: 1.25)),
        const SizedBox(height: 6),
        Text(
          'Artículos clínicos, guías de respiración y ejercicios adaptados a tus '
          'patrones emocionales detectados por IA.',
          style: _body(13, h: 1.6),
        ),
      ],
    );
  }

  Widget _recommendedCard(Resource r) {
    final focus = r.tags.any((t) => t.contains('somatic'))
        ? 'Enfoque Somático'
        : r.tags.any((t) => t.contains('respira'))
            ? 'Respiración consciente'
            : 'Práctica guiada';
    final hasAudio =
        r.audioUrl != null || r.tags.any((t) => t.contains('audio'));

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(Icons.auto_awesome, size: 18, color: _R.accent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Recomendación de hoy • Basado en tus registros de estrés',
                  style: _body(11.5, w: FontWeight.w600, c: _R.ink, h: 1.45),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(r.title, style: _head(21, ls: -0.4, h: 1.3)),
          const SizedBox(height: 8),
          Text(r.description, style: _body(13, h: 1.6, c: _R.body)),
          const SizedBox(height: 16),
          _heroImage(r),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.schedule, size: 16, color: _R.accent),
              const SizedBox(width: 7),
              Text('${r.readMinutes} min de lectura',
                  style: _body(12.5, w: FontWeight.w600, c: _R.ink)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              _meta(Icons.accessibility_new, focus),
              if (hasAudio) _meta(Icons.headphones, 'Audio guiado'),
            ],
          ),
          const SizedBox(height: 18),
          _primaryButton(
            'Iniciar Guía Interactiva',
            icon: Icons.arrow_forward,
            onTap: () => _openDetail(r),
          ),
        ],
      ),
    );
  }

  Widget _heroImage(Resource r) {
    final caption = r.imageCaption ?? r.category;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 2.05,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _RemoteImage(
              url: r.imageUrl,
              fallbackIcon: Icons.spa_outlined,
              alignment: const Alignment(0, 0.25),
            ),
            Positioned.fill(
              child: ColoredBox(
                color: Color(0xFFD8C7A6).withValues(alpha: 0.10),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.38),
                    ],
                    stops: const [0.55, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.spa_outlined, size: 13, color: Colors.white),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _body(11.5,
                          w: FontWeight.w600, c: Colors.white, h: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: _R.ink),
        const SizedBox(width: 6),
        Text(label, style: _body(12, w: FontWeight.w500, c: _R.ink)),
      ],
    );
  }

  Widget _quickToolsCard() {
    final tools = _tools;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.graphic_eq, size: 15, color: _R.accent),
              const SizedBox(width: 6),
              Text('Contención Inmediata',
                  style: _body(11, w: FontWeight.w800, c: _R.ink, ls: 0.4)),
            ],
          ),
          const SizedBox(height: 9),
          Text('Herramientas Inmediatas', style: _head(20, h: 1.3)),
          const SizedBox(height: 4),
          Text(
            'Ejercicios guiados para estabilizar el pulso y calmar la mente.',
            style: _body(13, h: 1.55),
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < tools.length; i++) ...[
            if (i > 0) const SizedBox(height: 18),
            _toolRow(tools[i]),
          ],
        ],
      ),
    );
  }

  Widget _toolRow(Resource r) {
    final meta = r.tags.isNotEmpty
        ? '${r.readMinutes} min · ${_capitalize(r.tags.first)}'
        : r.kindLabel;
    final (label, icon) = switch (r.kind) {
      ResourceKind.audio => ('Escuchar', Icons.play_arrow),
      ResourceKind.guide => ('Abrir', null),
      _ => ('Comenzar', null),
    };

    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(color: _R.mint, shape: BoxShape.circle),
          child: Icon(
            r.kind == ResourceKind.audio
                ? Icons.nightlight_outlined
                : Icons.air,
            size: 21,
            color: _R.forest,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r.title, style: _head(16, w: FontWeight.w700, h: 1.35)),
              const SizedBox(height: 2),
              Text(meta, style: _body(11.5, h: 1.5)),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _compactButton(label, icon: icon, onTap: () => _openDetail(r)),
      ],
    );
  }

  Widget _compactButton(String label,
      {IconData? icon, required VoidCallback onTap}) {
    return Material(
      color: _R.forest,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: Colors.white),
                const SizedBox(width: 3),
              ],
              Text(label,
                  style: _body(12.5, w: FontWeight.w700, c: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _readingsCard() {
    final articles = _filteredArticles;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('EVIDENCIA & SALUD MENTAL',
                        style: _body(11,
                            w: FontWeight.w800, c: _R.ink, ls: 0.4)),
                    const SizedBox(height: 3),
                    Text('Lecturas Clínicas', style: _head(19, h: 1.3)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified, size: 16, color: _R.accent),
                  const SizedBox(width: 5),
                  Text('Revisión Médica',
                      style: _body(11, w: FontWeight.w600, c: _R.ink)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _search,
            onChanged: (value) => setState(() => _query = value),
            textInputAction: TextInputAction.search,
            style: _body(13.5, c: _R.ink),
            decoration: InputDecoration(
              hintText: 'Buscar por técnica, emoción o síntoma',
              hintStyle: _body(13, c: _R.muted),
              prefixIcon: const Icon(Icons.search, size: 20, color: _R.muted),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 42, minHeight: 20),
              filled: true,
              fillColor: _R.input,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    BorderSide(color: _R.border.withValues(alpha: 0.55)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    BorderSide(color: _R.border.withValues(alpha: 0.55)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _R.accent, width: 1.3),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => _categoryChip(_categories[i]),
            ),
          ),
          const SizedBox(height: 12),
          if (articles.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Column(
                children: [
                  const Icon(Icons.search_off, size: 26, color: _R.muted2),
                  const SizedBox(height: 8),
                  Text(
                    'No encontramos lecturas con esa búsqueda.',
                    textAlign: TextAlign.center,
                    style: _body(13, h: 1.5),
                  ),
                ],
              ),
            )
          else
            for (var i = 0; i < articles.length; i++) ...[
              if (i > 0) const SizedBox(height: 14),
              _articleRow(articles[i]),
            ],
          const SizedBox(height: 8),
          _savedFooter(),
        ],
      ),
    );
  }

  Widget _categoryChip(String label) {
    final selected = _category == label;
    return GestureDetector(
      onTap: () => setState(() => _category = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _R.forest : _R.input,
          borderRadius: BorderRadius.circular(99),
          border: selected
              ? null
              : Border.all(color: _R.border.withValues(alpha: 0.6)),
        ),
        child: Center(
          child: Text(
            label,
            style: _body(13,
                w: FontWeight.w600, c: selected ? Colors.white : _R.ink),
          ),
        ),
      ),
    );
  }

  Widget _articleRow(Resource r) {
    final saved = _saved.contains(r.id);
    final byline = [
      if (r.author != null && r.author!.trim().isNotEmpty) r.author!,
      '${r.readMinutes} min',
    ].join(' • ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openDetail(r),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 74,
                  height: 74,
                  child: _RemoteImage(
                    url: r.imageUrl,
                    fallbackIcon: Icons.menu_book_outlined,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(byline, style: _body(11, w: FontWeight.w500, c: _R.muted2)),
                    const SizedBox(height: 4),
                    Text(
                      r.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: _body(14,
                          w: FontWeight.w700, c: _R.ink, h: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 2),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: saved ? 'Quitar de guardados' : 'Guardar artículo',
                onPressed: () => _toggleSaved(r),
                icon: Icon(
                  saved ? Icons.bookmark : Icons.bookmark_border,
                  size: 19,
                  color: saved ? _R.forest : _R.muted2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _savedFooter() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _showSaved,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.bookmark_border, size: 20, color: _R.ink),
              Expanded(
                child: Text(
                  'Ver todos los artículos guardados (${_savedArticles.length})',
                  textAlign: TextAlign.center,
                  style: _body(14.5, w: FontWeight.w700, c: _R.ink, h: 1.35),
                ),
              ),
              const SizedBox(width: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _safetyCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration:
                    const BoxDecoration(color: _R.mint, shape: BoxShape.circle),
                child: const Icon(Icons.shield_outlined,
                    size: 20, color: _R.forest),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Espacio Seguro y Avalado',
                        style: _head(17, w: FontWeight.w800, h: 1.3)),
                    const SizedBox(height: 6),
                    Text(
                      'Todo el material está avalado por profesionales de la salud '
                      'mental según lineamientos de psicoeducación clínica. Estos '
                      'ejercicios complementan tu bienestar, pero no sustituyen el '
                      'acompañamiento psicoterapéutico.',
                      style: _body(13, h: 1.6, c: _R.body),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _showHelp,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                          color: _R.mint, shape: BoxShape.circle),
                      child: const Icon(Icons.help_outline,
                          size: 18, color: _R.forest),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '¿Necesitas ayuda urgente? Ir a Directorio & SOS',
                        style: _body(14,
                            w: FontWeight.w700, c: _R.ink, h: 1.4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18, color: _R.ink),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton(String label,
      {required VoidCallback onTap, IconData? icon}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _R.forest.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: _R.forest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            height: 54,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: _body(15, w: FontWeight.w600, c: _R.bg)),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(icon, size: 17, color: _R.bg),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

// ---------------- Widgets auxiliares ----------------

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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _R.forest.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Imagen remota con un degradado vegetal como respaldo mientras carga o si
/// la API no devuelve una fotografía válida.
class _RemoteImage extends StatelessWidget {
  const _RemoteImage({
    this.url,
    required this.fallbackIcon,
    this.alignment = Alignment.center,
  });

  final String? url;
  final IconData fallbackIcon;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE9F1EA), Color(0xFFC9DCCF)],
        ),
      ),
      child: Center(
        child: Icon(fallbackIcon, size: 26, color: _R.accent),
      ),
    );

    if (url == null || url!.trim().isEmpty) return fallback;

    return Image.network(
      url!,
      fit: BoxFit.cover,
      alignment: alignment,
      errorBuilder: (_, _, _) => fallback,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : fallback,
    );
  }
}
