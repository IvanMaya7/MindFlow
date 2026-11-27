import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/auth_service.dart' show ApiException;
import '../data/contacts_service.dart';
import '../providers/auth_provider.dart';

// Paleta de Perfil (tomada del diseño en Figma)
class _Pf {
  static const bg = Color(0xFFFFF8F1);
  static const ink = Color(0xFF1F1B13);
  static const body = Color(0xFF424843);
  static const forest = Color(0xFF3E5F4D);
  static const chipText = Color(0xFF486A57);
  static const mintChip = Color(0xFFC3E8D1);
  static const cream = Color(0xFFF6EDDF);
  static const contactBg = Color(0xFFFCF2E4);
  static const note = Color(0xFFF0E7D9);
  static const avatar = Color(0xFF4D6453);
  static const tagBg = Color(0x66D8C7A6);
  static const tagText = Color(0xFF5A4E34);
  static const sand = Color(0xFFF2E1BE);
  static const sandText = Color(0xFF231A06);
  static const iconBg = Color(0xFFCFE9D4);
  static const terracotta = Color(0xFFC87355);
}

TextStyle _hd(double size,
        {FontWeight w = FontWeight.w600, Color c = _Pf.ink, double? ls, double? h}) =>
    GoogleFonts.nunitoSans(
        fontSize: size, fontWeight: w, color: c, letterSpacing: ls, height: h);

TextStyle _tx(double size,
        {FontWeight w = FontWeight.w400, Color c = _Pf.body, double? ls, double? h}) =>
    GoogleFonts.inter(
        fontSize: size, fontWeight: w, color: c, letterSpacing: ls, height: h);

String _initials(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts[1][0]).toUpperCase();
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<List<TrustedContact>> _contacts = ContactsService().list();

  void _reloadContacts() {
    setState(() => _contacts = ContactsService().list());
  }

  void _soon() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Próximamente')));
  }

  Future<void> _call(String phone) async {
    final messenger = ScaffoldMessenger.of(context);
    final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    try {
      final ok = await launchUrl(Uri(scheme: 'tel', path: clean),
          mode: LaunchMode.externalApplication);
      if (!ok) throw Exception('sin aplicación');
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        content: Text('No se pudo abrir la aplicación del teléfono en este dispositivo'),
      ));
    }
  }

  Future<void> _logout() async {
    final auth = context.read<AuthProvider>();
    final nav = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _Pf.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('¿Cerrar sesión?', style: _hd(18)),
        content: Text('Tendrás que iniciar sesión de nuevo para entrar a tu espacio.',
            style: _tx(14, h: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar', style: _tx(14, w: FontWeight.w600)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: _Pf.forest),
            child: Text('Cerrar sesión',
                style: _tx(14, w: FontWeight.w700, c: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    // Volvemos al inicio de la pila; el cambio a login lo hace el AuthProvider
    nav.popUntil((r) => r.isFirst);
    auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final name = (user?.displayName ?? '').trim();
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: _Pf.bg,
      appBar: AppBar(
        backgroundColor: _Pf.bg.withValues(alpha: 0.92),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        toolbarHeight: 64,
        titleSpacing: 0,
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: _Pf.ink),
        ),
        title: Text('Perfil y ajustes', style: _hd(18, ls: -0.45)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _profileCard(name, email),
                const SizedBox(height: 20),
                _contactsCard(),
                const SizedBox(height: 20),
                _privacyCard(),
                const SizedBox(height: 20),
                _logoutButton(),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline, size: 12, color: _Pf.body),
                    const SizedBox(width: 6),
                    Text('MindFlow', style: _tx(11, w: FontWeight.w500, ls: 0.22)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- Tarjeta de perfil ----------------

  Widget _profileCard(String name, String email) {
    return _Card(
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration:
                const BoxDecoration(color: _Pf.avatar, shape: BoxShape.circle),
            child: Text(_initials(name),
                style: _hd(22, w: FontWeight.w700, c: Colors.white)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.isEmpty ? 'Tu cuenta' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _hd(18, h: 1.45)),
                Text(email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _tx(13, h: 1.5)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: _Pf.mintChip,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            color: _Pf.avatar, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text('Cuenta activa',
                          style: _tx(11,
                              w: FontWeight.w600, c: _Pf.chipText, ls: 0.22, h: 1.45)),
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

  // ---------------- Contactos de confianza ----------------

  Widget _contactsCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, size: 18, color: _Pf.terracotta),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Red de apoyo & contactos', style: _hd(18, h: 1.45)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Las personas a las que puedes avisar desde Ayuda cuando necesites '
            'hablar con alguien. Tú decides cuándo.',
            style: _tx(13, h: 1.6),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<TrustedContact>>(
            future: _contacts,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                      child: CircularProgressIndicator(color: _Pf.forest)),
                );
              }
              if (snap.hasError) {
                final e = snap.error;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e is ApiException
                          ? e.message
                          : 'No se pudieron cargar tus contactos',
                      style: _tx(13, c: _Pf.terracotta),
                    ),
                    TextButton(
                      onPressed: _reloadContacts,
                      child: Text('Reintentar',
                          style: _tx(13, w: FontWeight.w700, c: _Pf.forest)),
                    ),
                  ],
                );
              }
              final list = snap.data ?? [];
              if (list.isEmpty) {
                return Text('Aún no tienes contactos de confianza guardados.',
                    style: _tx(13));
              }
              return Column(
                children: [
                  for (var i = 0; i < list.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    _contactTile(list[i], i),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Material(
            color: _Pf.cream,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _soon,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_circle_outline,
                        size: 17, color: _Pf.forest),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text('Añadir contacto de confianza',
                          textAlign: TextAlign.center,
                          style: _tx(14, w: FontWeight.w600, c: _Pf.forest)),
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

  Widget _contactTile(TrustedContact c, int i) {
    final alt = i.isOdd;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _Pf.contactBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: alt ? _Pf.sand : _Pf.mintChip,
              shape: BoxShape.circle,
            ),
            child: Text(_initials(c.name),
                style: _tx(15,
                    w: FontWeight.w600, c: alt ? _Pf.sandText : _Pf.chipText)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _tx(15, w: FontWeight.w600, c: _Pf.ink, h: 1.35)),
                const SizedBox(height: 2),
                if (c.relation.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _Pf.tagBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(c.relation,
                        style: _tx(11,
                            w: FontWeight.w500, c: _Pf.tagText, ls: 0.22, h: 1.45)),
                  ),
                const SizedBox(height: 2),
                Text(c.phone, style: _tx(13, ls: 0.3, h: 1.5)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Llamar',
            onPressed: () => _call(c.phone),
            icon: const Icon(Icons.call_outlined, size: 19, color: _Pf.forest),
          ),
        ],
      ),
    );
  }

  // ---------------- Privacidad ----------------

  Widget _privacyCard() {
    Widget row(IconData icon, String text) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 16, color: _Pf.forest),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: _tx(13, h: 1.55))),
          ],
        );

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                    color: _Pf.iconBg, shape: BoxShape.circle),
                child: const Icon(Icons.lock_outline, size: 17, color: _Pf.forest),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tu privacidad', style: _hd(18, h: 1.45)),
                    Text('Lo que sí puedes esperar de MindFlow', style: _tx(13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          row(Icons.qr_code_2,
              'Cuando compartes tu reporte con un especialista, no incluye lo que '
              'escribiste en tu diario.'),
          const SizedBox(height: 12),
          row(Icons.timer_outlined,
              'El enlace del reporte expira en 15 minutos y se corta al cerrar la ventana.'),
          const SizedBox(height: 12),
          row(Icons.https_outlined,
              'La comunicación con el servidor viaja por una conexión segura (HTTPS).'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _Pf.note,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.shield_outlined, size: 16, color: _Pf.forest),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'MindFlow es una herramienta de acompañamiento. No sustituye la '
                    'atención de un psicólogo o psiquiatra profesional.',
                    style: _tx(13, h: 1.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Cerrar sesión ----------------

  Widget _logoutButton() {
    return Material(
      color: _Pf.cream,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _logout,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout, size: 16, color: _Pf.forest),
              const SizedBox(width: 8),
              Text('Cerrar sesión',
                  style: _tx(15, w: FontWeight.w600, c: _Pf.forest)),
            ],
          ),
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _Pf.forest.withValues(alpha: 0.07),
            blurRadius: 20,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}