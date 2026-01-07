/// Helpers para formateo de texto en formularios de autenticación
/// Estilo: Programación competitiva - una función = un problema

import 'package:flutter/services.dart';

// ============================================================================
// FUNCIONES DE FORMATEO DE TEXTO
// ============================================================================

/// Formatea un número de teléfono con guiones (XXX-XXX-XXX)
/// Input: String sin formato "987654321"
/// Output: String formateado "987-654-321"
String formatPhoneNumber(String phone) {
  final text = phone.replaceAll('-', '');
  if (text.isEmpty) return '';
  if (text.length <= 3) return text;
  if (text.length <= 6) return '${text.substring(0, 3)}-${text.substring(3)}';
  return '${text.substring(0, 3)}-${text.substring(3, 6)}-${text.substring(6)}';
}

/// Formatea un código de verificación con guión (XXX-XXX)
/// Input: String sin formato "123456"
/// Output: String formateado "123-456"
String formatVerificationCode(String code) {
  final text = code.replaceAll('-', '');
  if (text.isEmpty) return '';
  if (text.length <= 3) return text;
  return '${text.substring(0, 3)}-${text.substring(3)}';
}

/// Remueve todos los guiones de un string
/// Input: "987-654-321"
/// Output: "987654321"
String removeHyphens(String text) {
  return text.replaceAll('-', '');
}

/// Extrae solo dígitos de un string
/// Input: "abc123def456"
/// Output: "123456"
String extractDigits(String text) {
  return text.replaceAll(RegExp(r'\D'), '');
}

/// Formatea un número con prefijo de país
/// Input: "987654321"
/// Output: "+51 987-654-321"
String formatPhoneWithCountryCode(String phone, {String countryCode = '+51'}) {
  final formatted = formatPhoneNumber(phone);
  return formatted.isEmpty ? '' : '$countryCode $formatted';
}

// ============================================================================
// TEXT INPUT FORMATTERS (para TextFormField)
// ============================================================================

/// TextInputFormatter para números de teléfono peruanos (9 dígitos con guiones)
/// Formatea automáticamente mientras el usuario escribe: XXX-XXX-XXX
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = removeHyphens(newValue.text);
    if (text.isEmpty) return newValue.copyWith(text: '');
    
    final buffer = StringBuffer();
    for (int i = 0; i < text.length && i < 9; i++) {
      if (i == 3 || i == 6) buffer.write('-');
      buffer.write(text[i]);
    }
    
    final string = buffer.toString();
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

/// TextInputFormatter para códigos de verificación (6 dígitos con guión)
/// Formatea automáticamente mientras el usuario escribe: XXX-XXX
class CodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = removeHyphens(newValue.text);
    if (text.isEmpty) return newValue.copyWith(text: '');
    
    final buffer = StringBuffer();
    for (int i = 0; i < text.length && i < 6; i++) {
      if (i == 3) buffer.write('-');
      buffer.write(text[i]);
    }
    
    final string = buffer.toString();
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

/// Crea un PhoneNumberFormatter
/// Output: TextInputFormatter configurado para teléfonos
PhoneNumberFormatter createPhoneFormatter() {
  return PhoneNumberFormatter();
}

/// Crea un CodeFormatter
/// Output: TextInputFormatter configurado para códigos
CodeFormatter createCodeFormatter() {
  return CodeFormatter();
}

/// Crea lista de formatters para campo de teléfono
/// Output: Lista con FilteringTextInputFormatter + LengthLimiter + PhoneFormatter
List<TextInputFormatter> createPhoneInputFormatters() {
  return [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(9),
    PhoneNumberFormatter(),
  ];
}

/// Crea lista de formatters para campo de código
/// Output: Lista con FilteringTextInputFormatter + LengthLimiter + CodeFormatter
List<TextInputFormatter> createCodeInputFormatters() {
  return [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(6),
    CodeFormatter(),
  ];
}
