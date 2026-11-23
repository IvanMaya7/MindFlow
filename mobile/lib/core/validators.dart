class Validators {
  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

  static String? email(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Ingresa tu correo';
    if (value.length > 254 || !_emailRe.hasMatch(value)) return 'Correo inválido';
    return null;
  }

  /// Para crear cuenta: mínimo 8, con letras y números.
  static String? newPassword(String? v) {
    final value = v ?? '';
    if (value.isEmpty) return 'Ingresa una contraseña';
    if (value.length < 8) return 'Debe tener al menos 8 caracteres';
    if (value.length > 72) return 'No puede tener más de 72 caracteres';
    if (!RegExp(r'[A-Za-z]').hasMatch(value)) return 'Incluye al menos una letra';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Incluye al menos un número';
    return null;
  }

  /// Para iniciar sesión: solo que no esté vacía.
  static String? requiredPassword(String? v) =>
      (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null;

  static String? name(String? v, {String empty = 'Ingresa tu nombre'}) {
    final value = v?.trim() ?? '';
    if (value.length < 2) return empty;
    if (value.length > 60) return 'Es demasiado largo';
    return null;
  }

  static String? phone(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10 || digits.length > 15) {
      return 'Ingresa un número válido (mínimo 10 dígitos)';
    }
    return null;
  }
}