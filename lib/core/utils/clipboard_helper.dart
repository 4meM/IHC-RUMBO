/// Helper para operaciones con portapapeles
/// Estilo: Programación competitiva - una función = un problema

import 'package:flutter/services.dart';

// ============================================================================
// FUNCIONES DE PORTAPAPELES
// ============================================================================

/// Copia texto al portapapeles
/// Input: String con texto a copiar
/// Output: Future<void>
Future<void> copyToClipboard(String text) async {
  await Clipboard.setData(ClipboardData(text: text));
}

/// Obtiene texto del portapapeles
/// Input: ninguno
/// Output: Future<String?> con el texto (null si está vacío o hay error)
Future<String?> getClipboardText() async {
  try {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    return clipboardData?.text;
  } catch (e) {
    return null;
  }
}

/// Verifica si el portapapeles contiene texto
/// Input: ninguno
/// Output: Future<bool> indicando si hay texto
Future<bool> hasClipboardText() async {
  final text = await getClipboardText();
  return text != null && text.isNotEmpty;
}

/// Obtiene texto del portapapeles si existe, sino retorna valor por defecto
/// Input: String con valor por defecto
/// Output: Future<String> con texto del portapapeles o valor por defecto
Future<String> getClipboardTextOrDefault(String defaultValue) async {
  final text = await getClipboardText();
  return text ?? defaultValue;
}

/// Copia texto y retorna si fue exitoso
/// Input: String con texto a copiar
/// Output: Future<bool> indicando si se copió exitosamente
Future<bool> tryCopyToClipboard(String text) async {
  try {
    await copyToClipboard(text);
    return true;
  } catch (e) {
    return false;
  }
}

// ============================================================================
// FUNCIONES ESPECÍFICAS PARA AUTENTICACIÓN
// ============================================================================

/// Intenta pegar un código de verificación del portapapeles
/// Solo pega si es un código válido de 6 dígitos (con o sin guión)
/// Input: ninguno
/// Output: Future<String?> con código (null si no hay código válido)
Future<String?> pasteVerificationCode() async {
  try {
    final text = await getClipboardText();
    if (text == null) return null;
    
    final trimmed = text.trim();
    final digitsOnly = trimmed.replaceAll('-', '');
    
    // Verificar que sea un código de 6 dígitos
    if (RegExp(r'^\d{6}$').hasMatch(digitsOnly)) {
      return trimmed;
    }
    
    return null;
  } catch (e) {
    return null;
  }
}

/// Intenta pegar un número de teléfono del portapapeles
/// Solo pega si es un número válido de 9 dígitos (con o sin guiones)
/// Input: ninguno
/// Output: Future<String?> con teléfono (null si no hay teléfono válido)
Future<String?> pastePhoneNumber() async {
  try {
    final text = await getClipboardText();
    if (text == null) return null;
    
    final trimmed = text.trim();
    final digitsOnly = trimmed.replaceAll('-', '');
    
    // Verificar que sea un teléfono de 9 dígitos
    if (RegExp(r'^\d{9}$').hasMatch(digitsOnly)) {
      return trimmed;
    }
    
    return null;
  } catch (e) {
    return null;
  }
}

/// Intenta pegar cualquier dato numérico del portapapeles
/// Input: int con longitud esperada
/// Output: Future<String?> con número (null si no cumple longitud)
Future<String?> pasteNumericData(int expectedLength) async {
  try {
    final text = await getClipboardText();
    if (text == null) return null;
    
    final digitsOnly = text.replaceAll(RegExp(r'\D'), '');
    
    if (digitsOnly.length == expectedLength) {
      return text.trim();
    }
    
    return null;
  } catch (e) {
    return null;
  }
}

/// Limpia el portapapeles
/// Input: ninguno
/// Output: Future<void>
Future<void> clearClipboard() async {
  await Clipboard.setData(const ClipboardData(text: ''));
}

/// Verifica si el portapapeles contiene un patrón específico
/// Input: RegExp con patrón a buscar
/// Output: Future<bool> indicando si el portapapeles coincide con el patrón
Future<bool> clipboardMatches(RegExp pattern) async {
  final text = await getClipboardText();
  if (text == null) return false;
  return pattern.hasMatch(text);
}
