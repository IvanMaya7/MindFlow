import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/resource.dart';

class _D {
  static const bg = Color(0xFFF4EBDD);
  static const ink = Color(0xFF1A2421);
  static const body = Color(0xFF263B30);
  static const muted = Color(0xFF566A60);
  static const muted2 = Color(0xFF556F60);
  static const forest = Color(0xFF1E3A2B);
  static const accent = Color(0xFF3B6E51);
  static const border = Color(0xFFD1E2D6);
  static const mint = Color(0xFFE4F0E7);
  static const sageRing = Color(0xFFC9DCCF);
}

TextStyle _head(double size,
        {FontWeight w = FontWeight.w800,
        Color c = _D.ink,
        double? ls,
        double? h}) =>
    GoogleFonts.nunitoSans(
        fontSize: size, fontWeight: w, color: c, letterSpacing: ls, height: h);

TextStyle _body(double size,
        {FontWeight w = FontWeight.w400,
        Color c = _D.muted,
        double? ls,
        double? h}) =>
    GoogleFonts.inter(
        fontSize: size, fontWeight: w, color: c, letterSpacing: ls, height: h);

class ResourceDetailScreen extends StatefulWidget {
  const ResourceDetailScreen({
    super.key,
    required this.resource,
    required this.saved,
    required this.onSavedChanged,
  });

  final Resource resource;
  final bool saved;
  final Future<void> Function(bool) onSavedChanged;

  @override
  State<ResourceDetailScreen> createState() => _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends State<ResourceDetailScreen> {
  late bool _saved = widget.saved;

  Future<void> _toggleSaved() async {
    final next = !_saved;
    setState(() => _saved = next);
    await widget.onSavedChanged(next);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(next
            ? 'Artículo guardado para leer después'
            : 'Artículo quitado de guardados'),
      ),
    );
  }

  void _startSession() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _D.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _GuideSessionSheet(resource: widget.resource),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.resource;
    final paragraphs = (r.isReadable ? r.content! : r.description)
        .split(RegExp(r'\n\s*\n'))
        .where((p) => p.trim().isNotEmpty)
        .toList();

    final isPractice = r.kind != ResourceKind.article;

    return Scaffold(
      backgroundColor: _D.bg,
      appBar: AppBar(
        backgroundColor: _D.bg.withValues(alpha: 0.92),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22, color: _D.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Recursos', style: _head(17)),
            Text('Lectura psicoeducativa',
                style: _body(11, w: FontWeight.w500, ls: 0.2)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _saved ? 'Quitar de guardados' : 'Guardar artículo',
            onPressed: _toggleSaved,
            icon: Icon(
              _saved ? Icons.bookmark : Icons.bookmark_border,
              size: 22,
              color: _D.forest,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _DetailImage(
                          url: r.imageUrl,
                          fallbackIcon: isPractice
                              ? Icons.spa_outlined
                              : Icons.menu_book_outlined,
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.4),
                                ],
                                stops: const [0.5, 1],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 14,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _D.bg.withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(r.category,
                                    style: _body(11,
                                        w: FontWeight.w700, c: _D.forest)),
                              ),
                              const SizedBox(width: 8),
                              if (r.clinical)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _D.forest.withValues(alpha: 0.88),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.verified,
                                          size: 12, color: _D.bg),
                                      const SizedBox(width: 4),
                                      Text('Revisión médica',
                                          style: _body(10.5,
                                              w: FontWeight.w600, c: _D.bg)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(r.title, style: _head(25, ls: -0.5, h: 1.28)),
                const SizedBox(height: 8),
                Text(
                  [
                    if (r.author != null && r.author!.trim().isNotEmpty)
                      r.author!,
                    r.kindLabel,
                  ].join(' • '),
                  style: _body(12, w: FontWeight.w500, c: _D.muted2),
                ),
                const SizedBox(height: 12),
                Text(r.description,
                    style: _body(14.5, h: 1.65, c: _D.body)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _D.forest.withValues(alpha: 0.07),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isPractice) ...[
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                  color: _D.mint, shape: BoxShape.circle),
                              child: const Icon(Icons.self_improvement,
                                  size: 17, color: _D.forest),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text('La práctica, paso a paso',
                                  style: _head(17, h: 1.3)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                      ],
                      for (var i = 0; i < paragraphs.length; i++) ...[
                        if (i > 0) const SizedBox(height: 14),
                        Text(paragraphs[i].trim(),
                            style: _body(14, h: 1.75, c: _D.body)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _D.mint.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.shield_outlined,
                            size: 17, color: _D.forest),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Contenido psicoeducativo revisado por profesionales. '
                          'Complementa tu bienestar, pero no sustituye la '
                          'psicoterapia ni la atención de emergencia.',
                          style: _body(12.5, h: 1.55, c: _D.body),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (isPractice)
                  _primaryButton(
                    switch (r.kind) {
                      ResourceKind.audio => 'Escuchar sesión guiada',
                      ResourceKind.guide => 'Iniciar Guía Interactiva',
                      _ => 'Comenzar ejercicio',
                    },
                    icon: r.kind == ResourceKind.audio
                        ? Icons.headphones
                        : Icons.play_arrow,
                    onTap: _startSession,
                  )
                else
                  _outlineButton(
                    _saved ? 'Guardado en tus lecturas' : 'Guardar para leer después',
                    icon: _saved ? Icons.bookmark : Icons.bookmark_border,
                    onTap: _toggleSaved,
                  ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, size: 14),
                    label: Text('Volver a Recursos',
                        style: _body(13, w: FontWeight.w500)),
                    style: TextButton.styleFrom(foregroundColor: _D.muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _primaryButton(String label,
      {required VoidCallback onTap, IconData? icon}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _D.forest.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: _D.forest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            height: 54,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: _body(15, w: FontWeight.w600, c: _D.bg)),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(icon, size: 18, color: _D.bg),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _outlineButton(String label,
      {required VoidCallback onTap, IconData? icon}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _D.border, width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: _D.forest),
                const SizedBox(width: 8),
              ],
              Text(label,
                  style: _body(14, w: FontWeight.w600, c: _D.forest)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- Sesión guiada ----------------

class _GuideSessionSheet extends StatefulWidget {
  const _GuideSessionSheet({required this.resource});

  final Resource resource;

  @override
  State<_GuideSessionSheet> createState() => _GuideSessionSheetState();
}

class _GuideSessionSheetState extends State<_GuideSessionSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.resource;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: _D.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 20),
            Text(r.category.toUpperCase(),
                style: _body(10.5, w: FontWeight.w800, c: _D.accent, ls: 1.1)),
            const SizedBox(height: 6),
            Text('Respira conmigo', style: _head(23, h: 1.25)),
            const SizedBox(height: 6),
            Text(
              r.kind == ResourceKind.audio
                  ? 'Sigue el ritmo del círculo mientras te acompañas con el audio.'
                  : 'Sigue el círculo y permite que el cuerpo baje el ritmo.',
              textAlign: TextAlign.center,
              style: _body(13.5, h: 1.55),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 230,
              child: Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (_, _) {
                    final t = _controller.value;
                    final inhale = t < 1 / 3;
                    final hold = t >= 1 / 3 && t < 2 / 3;
                    final phase = inhale
                        ? 'Inhala'
                        : hold
                            ? 'Sostén'
                            : 'Exhala';
                    final progress = inhale
                        ? t * 3
                        : hold
                            ? 1.0
                            : 1 - (t - 2 / 3) * 3;
                    final scale = 0.74 + 0.26 * progress;

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 224,
                          height: 224,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: _D.sageRing, width: 1.5),
                          ),
                        ),
                        Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 210,
                            height: 210,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _D.mint,
                                  _D.border.withValues(alpha: 0.8),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _D.forest.withValues(alpha: 0.12),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(phase,
                                      style: _head(26,
                                          c: _D.forest, ls: -0.4)),
                                  const SizedBox(height: 2),
                                  Text('Inhala 4 · Sostén 4 · Exhala 4',
                                      style: _body(11,
                                          w: FontWeight.w500,
                                          c: _D.forest)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              '${r.title} · ${r.readMinutes} min',
              textAlign: TextAlign.center,
              style: _body(12.5, w: FontWeight.w600, c: _D.ink),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _D.border, width: 1.2),
                    ),
                    child: Center(
                      child: Text('Terminar sesión',
                          style: _body(14, w: FontWeight.w600, c: _D.forest)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Puedes cerrar cuando quieras. Escucha siempre a tu cuerpo.',
              textAlign: TextAlign.center,
              style: _body(11, c: _D.muted2),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailImage extends StatelessWidget {
  const _DetailImage({this.url, required this.fallbackIcon});

  final String? url;
  final IconData fallbackIcon;

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
        child: Icon(fallbackIcon, size: 34, color: _D.accent),
      ),
    );

    if (url == null || url!.trim().isEmpty) return fallback;

    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : fallback,
    );
  }
}
