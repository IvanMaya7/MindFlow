import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/auth_service.dart' show ApiException;
import '../data/contacts_service.dart';

// Paleta de Ayuda (tomada del diseño en Figma)
class _H {
  static const bg = Color(0xFFF4EBDD);
  static const ink = Color(0xFF1A2421);
  static const muted = Color(0xFF566A60);
  static const muted2 = Color(0xFF556F60);
  static const body = Color(0xFF263B30);
  static const forest = Color(0xFF1E3A2B);
  static const accent = Color(0xFF3B6E51);
  static const border = Color(0xFFD1E2D6);
  static const mint = Color(0xFFE4F0E7);
  static const cardBorder = Color(0xFFE4D8C7);
  static const cream = Color(0xFFF6EDDF);
  static const terracotta = Color(0xFFC87355);
  static const green = Color(0xFF10B981);
  static const mintBtn = Color(0xFFC3E8D1);
  static const mintBtnBorder = Color(0xFFABCFB8);
}

TextStyle _hd(double size,
        {FontWeight w = FontWeight.w800, Color c = _H.ink, double? ls, double? h}) =>
    GoogleFonts.nunitoSans(
        fontSize: size, fontWeight: w, color: c, letterSpacing: ls, height: h);

TextStyle _tx(double size,
        {FontWeight w = FontWeight.w400, Color c = _H.muted, double? ls, double? h}) =>
    GoogleFonts.inter(
        fontSize: size, fontWeight: w, color: c, letterSpacing: ls, height: h);

String _digits(String s) => s.replaceAll(RegExp(r'[^\d+]'), '');

Future<void> _openUri(BuildContext context, Uri uri) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) throw Exception('sin aplicación');
  } catch (_) {
    messenger.showSnackBar(const SnackBar(
      content: Text('No se pudo abrir la aplicación del teléfono en este dispositivo'),
    ));
  }
}

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  void _openResources() {
    Navigator.of(context).pop('resources');
  }

  void _openContacts() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _H.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _ContactsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _H.bg,
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
                const SizedBox(height: 20),
                _sosCard(),
                const SizedBox(height: 20),
                _specialistsCard(),
                const SizedBox(height: 20),
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
      backgroundColor: _H.bg.withValues(alpha: 0.92),
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      toolbarHeight: 64,
      titleSpacing: 16,
      automaticallyImplyLeading: false,
      shape: Border(bottom: BorderSide(color: _H.border.withValues(alpha: 0.6))),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _H.forest,
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
                Text('MINDFLOW · AYUDA',
                    overflow: TextOverflow.ellipsis,
                    style: _tx(10, w: FontWeight.w700, c: _H.muted2, ls: 1)),
                Text('Panel Diario', style: _hd(16, c: _H.forest)),
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
        color: _H.bg.withValues(alpha: 0.95),
        border: const Border(top: BorderSide(color: _H.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Estos textos le dicen al Inicio qué abrir al regresar
              _navItem(Icons.menu_book_outlined, 'Diario',
                  onTap: () => Navigator.of(context).pop('diary')),
              _navItem(Icons.show_chart, 'Progreso',
                  onTap: () => Navigator.of(context).pop('progress')),
              _navItem(Icons.eco_outlined, 'Inicio',
                  onTap: () => Navigator.of(context).pop()),
              _navItem(Icons.local_florist_outlined, 'Recursos',
                  onTap: _openResources),
              _navItem(Icons.volunteer_activism_outlined, 'Ayuda', selected: true),
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
                        const BoxDecoration(color: _H.mint, shape: BoxShape.circle),
                    child: Icon(icon, size: 18, color: _H.forest),
                  )
                : Icon(icon, size: 21, color: _H.muted2),
            const SizedBox(height: 2),
            Text(
              label,
              style: _tx(10,
                  w: selected ? FontWeight.w700 : FontWeight.w500,
                  c: selected ? _H.forest : _H.muted2),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Cabecera de página ----------------

  Widget _pageHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Red de Apoyo &\nProfesionales', style: _hd(26, ls: -0.65, h: 1.25)),
          const SizedBox(height: 6),
          Text(
            'Recursos de contención inmediata y, pronto, especialistas cerca de ti, en un entorno seguro.',
            style: _tx(13, h: 1.6),
          ),
        ],
      ),
    );
  }

  // ---------------- Tarjeta 1: asistencia inmediata ----------------

  Widget _sosCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _H.terracotta.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.favorite_border,
                          size: 17, color: _H.terracotta),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Asistencia Inmediata',
                              style: _hd(16, w: FontWeight.w700, h: 1.25)),
                          Text('Línea gratuita, sin juicio',
                              style: _tx(11, w: FontWeight.w600, c: _H.terracotta)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                  color: _H.mint,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: _H.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: _H.green, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text('24 horas',
                        style: _tx(11, w: FontWeight.w700, c: _H.forest)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Si sientes que la intensidad emocional sobrepasa tus herramientas actuales, '
            'un profesional especializado puede acompañarte en este instante.',
            style: _tx(13.5, c: _H.body, h: 1.6),
          ),
          const SizedBox(height: 16),
          Material(
            color: _H.forest,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openUri(context, Uri(scheme: 'tel', path: '8009112000')),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.phone_in_talk_outlined,
                          size: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Línea de la Vida',
                              style: _tx(14, w: FontWeight.w700, c: _H.bg)),
                          Text('800 911 2000 · Gratuita · 24 horas',
                              style: _tx(11, c: const Color(0xFFAFC8B4))),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward, size: 15, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Material(
            color: _H.cream,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _openContacts,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _H.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.group_outlined, size: 18, color: _H.forest),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Avisar a mis Contactos de Confianza',
                          style: _tx(13, w: FontWeight.w600, c: _H.forest)),
                    ),
                    const Icon(Icons.chevron_right, size: 18, color: _H.muted2),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text('¿Estás en peligro inmediato?', style: _tx(12)),
              ),
              TextButton(
                onPressed: () => _openUri(context, Uri(scheme: 'tel', path: '911')),
                style: TextButton.styleFrom(
                  foregroundColor: _H.terracotta,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                ),
                child: Text('Llama al 911',
                    style: _tx(12, w: FontWeight.w700, c: _H.terracotta)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- Tarjeta 2: especialistas (aún sin directorio) ----------------

  Widget _specialistsCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _H.mint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.verified_user_outlined,
                    size: 15, color: _H.accent),
              ),
              const SizedBox(width: 8),
              Text('Especialistas', style: _hd(16, h: 1.5)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Aquí encontrarás psicólogos y psicólogas verificados, con filtros por '
            'enfoque, modalidad y cercanía.',
            style: _tx(12.5, h: 1.25),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: _H.cream,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _H.cardBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.hourglass_empty, size: 18, color: _H.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Estamos preparando un directorio de especialistas verificados. '
                    'Mientras tanto, la Línea de la Vida y tus contactos de confianza '
                    'están disponibles arriba, a un toque.',
                    style: _tx(12, h: 1.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Tarjeta 3: reporte para el especialista ----------------

  Widget _shareCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _H.mint,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _H.border),
                ),
                child: const Icon(Icons.qr_code_2, size: 20, color: _H.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Comparte tu historial', style: _hd(16, h: 1.25)),
                    Text('Para que tu terapeuta no empiece de cero',
                        style: _tx(11.5, w: FontWeight.w700, c: _H.accent, h: 1.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Cuando tengas cita con un especialista, puedes mostrarle, solo si tú '
            'quieres, un reporte con tus promedios y tendencias. No incluye lo que '
            'escribiste en tu diario.',
            style: _tx(13, c: _H.body, h: 1.6),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: _H.cream,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _H.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_clock_outlined, size: 19, color: _H.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tú decides cuándo compartir',
                          style: _tx(12, w: FontWeight.w700, c: _H.ink)),
                      Text(
                        'El código QR expira en 15 minutos y se corta al cerrar la ventana.',
                        style: _tx(11, h: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Material(
            color: _H.mintBtn,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).pop('progress'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 17),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _H.mintBtnBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.show_chart, size: 16, color: _H.forest),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text('Generar reporte desde Progreso',
                          style: _tx(13, w: FontWeight.w700, c: _H.forest)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- Ventana de contactos de confianza ----------------

class _ContactsSheet extends StatefulWidget {
  const _ContactsSheet();

  @override
  State<_ContactsSheet> createState() => _ContactsSheetState();
}

class _ContactsSheetState extends State<_ContactsSheet> {
  late final Future<List<TrustedContact>> _future = ContactsService().list();

  static const _message =
      'Hola, estoy pasando un momento difícil y me gustaría hablar contigo. '
      '¿Puedes llamarme cuando puedas?';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tus contactos de confianza', style: _hd(18)),
            const SizedBox(height: 4),
            Text(
              'Se abrirá tu teléfono con el mensaje ya escrito. Tú decides si lo envías.',
              style: _tx(12.5, h: 1.5),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<TrustedContact>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator(color: _H.forest)),
                  );
                }
                if (snap.hasError) {
                  final e = snap.error;
                  return Text(
                    e is ApiException ? e.message : 'No se pudieron cargar tus contactos',
                    style: _tx(13, c: Theme.of(context).colorScheme.error),
                  );
                }
                final contacts = snap.data ?? [];
                if (contacts.isEmpty) {
                  return Text('No tienes contactos de confianza guardados.',
                      style: _tx(13));
                }
                return Column(
                  children: [
                    for (final c in contacts) ...[
                      _contactTile(c),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactTile(TrustedContact c) {
    final phone = _digits(c.phone);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _H.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c.name, style: _hd(15, w: FontWeight.w700)),
          const SizedBox(height: 2),
          Text('${c.relation} · ${c.phone}', style: _tx(12)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openUri(context, Uri(scheme: 'tel', path: phone)),
                  icon: const Icon(Icons.call_outlined, size: 16),
                  label: Text('Llamar', style: _tx(13, w: FontWeight.w600, c: _H.forest)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _H.forest,
                    side: const BorderSide(color: _H.cardBorder),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _openUri(
                    context,
                    Uri.parse('sms:$phone?body=${Uri.encodeComponent(_message)}'),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: Text('Mensaje',
                      style: _tx(13, w: FontWeight.w700, c: Colors.white)),
                  style: FilledButton.styleFrom(
                    backgroundColor: _H.forest,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _H.cardBorder),
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