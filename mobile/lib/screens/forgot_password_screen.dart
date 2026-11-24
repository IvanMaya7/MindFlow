import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/validators.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  int _step = 0; // 0 = pedir código, 1 = código + contraseña nueva
  bool _obscure = true;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // Espera de 60 s para reenviar, igual que el límite del servidor
  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  Future<void> _sendCode() async {
    if (!_emailFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final ok = await context
        .read<AuthProvider>()
        .requestPasswordReset(_emailCtrl.text.trim());
    if (!mounted || !ok) return;
    setState(() => _step = 1);
    _startCooldown();
  }

  Future<void> _resend() async {
    if (_cooldown > 0) return;
    final ok = await context
        .read<AuthProvider>()
        .requestPasswordReset(_emailCtrl.text.trim());
    if (!mounted || !ok) return;
    _startCooldown();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Te enviamos un nuevo código.')),
    );
  }

  Future<void> _reset() async {
    if (!_resetFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final ok = await context.read<AuthProvider>().resetPassword(
          email: _emailCtrl.text.trim(),
          code: _codeCtrl.text.trim(),
          newPassword: _passCtrl.text,
        );
    if (!mounted || !ok) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Contraseña actualizada. Ya puedes iniciar sesión.')),
    );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _step == 0 ? _stepEmail(auth, theme) : _stepReset(auth, theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorText(AuthProvider auth, ThemeData theme) {
    if (auth.error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        auth.error!,
        textAlign: TextAlign.center,
        style: TextStyle(color: theme.colorScheme.error),
      ),
    );
  }

  Widget _loading() => const SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );

  // ---------- Paso 1: correo ----------
  Widget _stepEmail(AuthProvider auth, ThemeData theme) {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('¿Olvidaste tu contraseña?',
              textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Escribe tu correo y te enviaremos un código de 6 dígitos.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'\s')),
            ],
            validator: Validators.email,
            onFieldSubmitted: (_) => _sendCode(),
          ),
          _errorText(auth, theme),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: auth.isLoading ? null : _sendCode,
            child: auth.isLoading ? _loading() : const Text('Enviar código'),
          ),
        ],
      ),
    );
  }

  // ---------- Paso 2: código + contraseña nueva ----------
  Widget _stepReset(AuthProvider auth, ThemeData theme) {
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Revisa tu correo',
              textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Si ${_emailCtrl.text.trim()} tiene una cuenta, recibirás un código. '
            'Vence en 15 minutos. Revisa también la carpeta de spam.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _codeCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: const InputDecoration(
              labelText: 'Código de 6 dígitos',
              prefixIcon: Icon(Icons.pin_outlined),
            ),
            validator: (v) =>
                (v == null || v.trim().length != 6) ? 'Ingresa los 6 dígitos' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Contraseña nueva',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: Validators.newPassword,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmCtrl,
            obscureText: _obscure,
            decoration: const InputDecoration(
              labelText: 'Confirmar contraseña',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            validator: (v) =>
                v != _passCtrl.text ? 'Las contraseñas no coinciden' : null,
            onFieldSubmitted: (_) => _reset(),
          ),
          _errorText(auth, theme),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: auth.isLoading ? null : _reset,
            child: auth.isLoading ? _loading() : const Text('Cambiar contraseña'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: (auth.isLoading || _cooldown > 0) ? null : _resend,
            child: Text(_cooldown > 0
                ? 'Reenviar código en ${_cooldown}s'
                : 'Reenviar código'),
          ),
          TextButton(
            onPressed: auth.isLoading ? null : () => setState(() => _step = 0),
            child: const Text('Cambiar correo'),
          ),
        ],
      ),
    );
  }
}