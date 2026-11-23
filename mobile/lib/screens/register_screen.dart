import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/auth_provider.dart';
import '../core/validators.dart';
import 'package:flutter/services.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _accountFormKey = GlobalKey<FormState>();
  final _contactFormKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _contactNameCtrl = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();

  int _step = 0; // 0 = cuenta, 1 = consentimiento IA, 2 = contacto
  bool _obscure = true;
  bool _aiConsent = false;
  bool _acceptedTerms = false;
  String? _relation;
  bool _checkingEmail = false;
  String? _takenEmail;

  static const _relations = ['Familiar', 'Pareja', 'Terapeuta', 'Amigo íntimo'];
  static const _sosColor = Color(0xFFC4694D);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _contactNameCtrl.dispose();
    _contactPhoneCtrl.dispose();
    super.dispose();
  }

  // ---------------- Lógica de pasos ----------------

  void _goTo(int step) {
    FocusScope.of(context).unfocus();
    context.read<AuthProvider>().clearError();
    setState(() => _step = step);
  }

    Future<void> _next() async {
    if (_step == 0) {
      if (!_accountFormKey.currentState!.validate()) return;
      FocusScope.of(context).unfocus();
      final auth = context.read<AuthProvider>();
      final email = _emailCtrl.text.trim().toLowerCase();

      setState(() => _checkingEmail = true);
      final available = await auth.isEmailAvailable(email);
      if (!mounted) return;
      setState(() => _checkingEmail = false);

      if (available == null) return; // error de red: auth.error ya se muestra abajo
      if (!available) {
        setState(() => _takenEmail = email);
        _accountFormKey.currentState!.validate(); // muestra el error en el campo
        return;
      }
      _goTo(1);
    } else if (_step == 1) {
      _goTo(2);
    }
  }

  Future<void> _submit() async {
    if (!_contactFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();

    final ok = await auth.register(
      displayName: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      allowAiAnalysis: _aiConsent,
      contactName: _contactNameCtrl.text.trim(),
      contactPhone: _contactPhoneCtrl.text.trim(),
      contactRelation: _relation,
    );

    if (!mounted) return;
    if (ok) {
      // AuthGate (main.dart) muestra el Home; cerramos esta pantalla.
      Navigator.of(context).pop();
    } else if (auth.error?.toLowerCase().contains('correo') ?? false) {
      // Error del correo: volvemos al paso 1 para corregirlo.
      setState(() => _step = 0);
    }
  }

  // ---------------- Estilos reutilizables ----------------

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _fieldFill => _isDark ? AppColors.darkBg : const Color(0xFFFBF1E2);
  Color get _softFill => _isDark ? AppColors.darkCard : const Color(0xFFEFE3D0);

  InputDecoration _dec(String hint, IconData icon, {Widget? suffix}) {
    final scheme = Theme.of(context).colorScheme;
    OutlineInputBorder border(Color? color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              color == null ? BorderSide.none : BorderSide(color: color, width: width),
        );
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 22),
      suffixIcon: suffix,
      filled: true,
      fillColor: _fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: border(null, 0),
      enabledBorder: border(null, 0),
      focusedBorder: border(scheme.primary, 1.5),
      errorBorder: border(scheme.error, 1),
      focusedErrorBorder: border(scheme.error, 1.5),
    );
  }

  Widget _labeled(String label, Widget field, {String? trailing}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            if (trailing != null) Text(trailing, style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 8),
        field,
      ],
    );
  }

  Widget _card(Widget child) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _cardHeader({
    required IconData icon,
    required String title,
    required String step,
    String? subtitle,
    String? eyebrow,
    Color? eyebrowColor,
    Color? iconBg,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconBg ?? _softFill,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: primary, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null)
                Text(eyebrow,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: eyebrowColor ?? primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    )),
              Text(title, style: theme.textTheme.titleLarge),
              if (subtitle != null)
                Text(subtitle, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _softFill,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(step, style: theme.textTheme.labelSmall),
        ),
      ],
    );
  }

  Widget _primaryButton(String label, VoidCallback? onPressed, {bool loading = false}) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 20),
              ],
            ),
    );
  }

  Widget _socialButton(Widget icon, String label) {
    return Expanded(
      child: Material(
        color: _fieldFill,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Próximamente'))),
          child: SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 8),
                Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- Paso 1: datos de cuenta ----------------

    Widget _stepAccount() {
    final theme = Theme.of(context);
    return Column(
      children: [
        _card(
          Form(
            key: _accountFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cardHeader(
                  icon: Icons.person_add_alt_1_outlined,
                  title: 'Datos de tu Cuenta',
                  subtitle: 'Acceso personal encriptado',
                  step: 'Paso 1 de 3',
                ),
                const SizedBox(height: 20),
                _labeled(
                  'Nombre completo',
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r"[\p{L}\p{M}' .\-]", unicode: true),
                      ),
                    ],
                    decoration: _dec('Ej. Sofía Morales', Icons.badge_outlined),
                    validator: (v) => Validators.name(v),
                  ),
                ),
                const SizedBox(height: 16),
                _labeled(
                  'Correo electrónico',
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _dec('sofia@ejemplo.com', Icons.mail_outline),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (v) {
                      final base = Validators.email(v);
                      if (base != null) return base;
                      if (v!.trim().toLowerCase() == _takenEmail) {
                        return 'Este correo ya tiene una cuenta. Inicia sesión.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _labeled(
                  'Contraseña maestra',
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    decoration: _dec(
                      'Mínimo 8, con letras y números',
                      Icons.lock_outline,
                      suffix: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => Validators.newPassword(v),
                  ),
                  trailing: 'Letras y números',
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('o accede rápidamente con',
                          style: theme.textTheme.bodySmall),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _socialButton(
                      const Text('G',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      'Google',
                    ),
                    const SizedBox(width: 12),
                    _socialButton(const Icon(Icons.apple, size: 22), 'Apple ID'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _primaryButton('Continuar', _next, loading: _checkingEmail),
      ],
    );
  }
  // ---------------- Paso 2: consentimiento de IA ----------------

  Widget _stepConsent() {
    final theme = Theme.of(context);
    return Column(
      children: [
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cardHeader(
                icon: Icons.auto_awesome,
                eyebrow: 'ANÁLISIS ASISTIDO',
                title: 'Consentimiento de IA',
                step: 'Paso 2 de 3',
                iconBg: AppColors.sage.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _fieldFill,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('Permitir análisis preventivo con IA',
                              style: theme.textTheme.titleMedium),
                        ),
                        Switch(
                          value: _aiConsent,
                          onChanged: (v) => setState(() => _aiConsent = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nuestra red neuronal médica analiza de manera confidencial y '
                      'anonimizada tus métricas de pulso, diario y registro de tensión '
                      'somática para anticipar momentos de sobrecarga sensorial y '
                      'sugerir intervenciones.',
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.verified_user_outlined,
                            size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tus datos están protegidos bajo estándares de privacidad '
                            'médica (GDPR / HIPAA). MindFlow es una herramienta de '
                            'regulación, no reemplaza psicoterapia clínica.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _primaryButton('Continuar', _next),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text('Es opcional. Puedes cambiarlo después en tu perfil.',
              textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
        ),
        const SizedBox(height: 4),
        TextButton(onPressed: () => _goTo(0), child: const Text('Atrás')),
      ],
    );
  }

  // ---------------- Paso 3: contacto de confianza ----------------
  Widget _stepContact(AuthProvider auth) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;

    return Column(
      children: [
        _card(
          Form(
            key: _contactFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cardHeader(
                  icon: Icons.shield,
                  eyebrow: 'PROTOCOLO SOS · REQUERIDO',
                  eyebrowColor: _sosColor,
                  title: 'Contacto de Confianza',
                  step: 'Paso 3 de 3',
                ),
                const SizedBox(height: 16),
                Text(
                  'Persona de tu red a quien notificaremos vía SMS seguro con '
                  'instrucciones guiadas solo si activas el botón SOS o se detecta '
                  'riesgo extremo sostenido.',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 20),
                _labeled(
                  'Nombre del contacto',
                  TextFormField(
                    controller: _contactNameCtrl,
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r"[\p{L}\p{M}' .()\-]", unicode: true),
                      ),
                    ],
                    decoration: _dec('Ej. Carmen R. (Mamá)', Icons.person_outline),
                    validator: (v) => Validators.contactName(v),
                  ),
                ),
                const SizedBox(height: 16),
                _labeled(
                  'Número telefónico',
                  TextFormField(
                    controller: _contactPhoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: _dec('+52 55 1234 5678', Icons.phone_outlined),
                    validator: (v) => Validators.phone(v),
                  ),
                ),
                const SizedBox(height: 16),
                _labeled(
                  'Parentesco o vínculo',
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _relations.map((r) {
                      final selected = _relation == r;
                      return ChoiceChip(
                        label: Text(r),
                        selected: selected,
                        showCheckmark: false,
                        shape: const StadiumBorder(),
                        side: BorderSide.none,
                        backgroundColor: _fieldFill,
                        selectedColor: primary,
                        labelStyle: TextStyle(
                          color: selected ? onPrimary : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (s) =>
                            setState(() => _relation = s ? r : null),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _acceptedTerms,
              activeColor: primary,
              checkColor: onPrimary,
              onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text.rich(
                  TextSpan(
                    style: theme.textTheme.bodySmall,
                    children: [
                      const TextSpan(text: 'Acepto los '),
                      TextSpan(
                        text: 'Términos de Convivencia Respetuosa',
                        style: TextStyle(
                          color: primary,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(
                          text: ' y el protocolo de custodia confidencial de datos somáticos.'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _primaryButton(
          'Crear mi cuenta segura',
          _acceptedTerms ? _submit : null,
          loading: auth.isLoading,
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: auth.isLoading ? null : () => _goTo(1),
          child: const Text('Atrás'),
        ),
      ],
    );
  }
  
  // ---------------- Pantalla ----------------

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final Widget stepContent;
    switch (_step) {
      case 0:
        stepContent = _stepAccount();
        break;
      case 1:
        stepContent = _stepConsent();
        break;
      default:
        stepContent = _stepContact(auth);
    }

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo(_step - 1);
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  children: [
                    // Etiqueta superior
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _softFill,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.eco, size: 16, color: primary),
                          const SizedBox(width: 6),
                          Text(
                            'MINDFLOW · ESPACIO SEGURO',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: primary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Logo
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: _softFill,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(Icons.eco, size: 32, color: primary),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Tu espacio de bienestar',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Crea tu cuenta segura para sincronizar tu progreso emocional, '
                      'mapas somáticos y tu red de contención.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    // Selector Iniciar Sesión / Crear Cuenta
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: _softFill,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                height: 46,
                                alignment: Alignment.center,
                                child: Text('Iniciar Sesión',
                                    style: theme.textTheme.titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: primary,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Crear Cuenta',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: theme.colorScheme.onPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: AppColors.sage,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: KeyedSubtree(
                        key: ValueKey(_step),
                        child: stepContent,
                      ),
                    ),
                    if (auth.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Text(
                          auth.error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}