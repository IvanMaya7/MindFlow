import 'package:flutter/services.dart';

/// Evita espacios al inicio y espacios seguidos (deja siempre uno solo).
class SingleSpaceFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(RegExp(r' {2,}'), ' ');
    if (text.startsWith(' ')) text = text.substring(1);
    if (text == newValue.text) return newValue;

    final removed = newValue.text.length - text.length;
    final offset = (newValue.selection.baseOffset - removed).clamp(0, text.length);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}