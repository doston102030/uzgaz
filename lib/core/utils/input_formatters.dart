import 'package:flutter/services.dart';

/// Formats a local Uzbek mobile number as `90 123 45 67` while the user
/// types. The `+998` part lives in the field's prefix, so only the nine
/// national digits are ever edited.
class UzPhoneInputFormatter extends TextInputFormatter {
  static const List<int> _groups = [2, 3, 2, 2];

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limited = digits.length > 9 ? digits.substring(0, 9) : digits;

    final buffer = StringBuffer();
    var index = 0;
    for (final size in _groups) {
      if (index >= limited.length) break;
      if (index > 0) buffer.write(' ');
      final end = (index + size).clamp(0, limited.length);
      buffer.write(limited.substring(index, end));
      index = end;
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Groups a number with spaces as it is typed: `120000` → `120 000`.
class ThousandsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i != 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Shared validators so error copy is identical everywhere.
class AppValidators {
  AppValidators._();

  static String? phone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 'Telefon raqamni kiriting';
    if (digits.length < 9) return 'Raqam to‘liq emas';
    return null;
  }

  static String? required(String? value, {String field = 'Maydon'}) {
    if ((value ?? '').trim().isEmpty) return '$field to‘ldirilishi shart';
    return null;
  }

  static String? fullName(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Ism va familiyani kiriting';
    if (text.length < 3) return 'Ism juda qisqa';
    return null;
  }
}
