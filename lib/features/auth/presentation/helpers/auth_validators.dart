/// Helpers para validación de formularios de autenticación
/// Estilo: Programación competitiva - una función = un problema

import 'text_formatters.dart';

// ============================================================================
// FUNCIONES DE VALIDACIÓN
// ============================================================================

/// Valida que un texto no esté vacío
/// Input: String? (puede ser null)
/// Output: bool indicando si es válido
bool isNotEmpty(String? value) {
  return value != null && value.trim().isNotEmpty;
}

/// Valida que un número de teléfono peruano sea correcto (9 dígitos)
/// Input: String con o sin guiones "987-654-321" o "987654321"
/// Output: bool indicando si es válido
bool isValidPhone(String? phone) {
  if (!isNotEmpty(phone)) return false;
  final digitsOnly = removeHyphens(phone!);
  return digitsOnly.length == 9 && RegExp(r'^\d{9}$').hasMatch(digitsOnly);
}

/// Valida que un código de verificación sea correcto (6 dígitos)
/// Input: String con o sin guión "123-456" o "123456"
/// Output: bool indicando si es válido
bool isValidVerificationCode(String? code) {
  if (!isNotEmpty(code)) return false;
  final digitsOnly = removeHyphens(code!);
  return digitsOnly.length == 6 && RegExp(r'^\d{6}$').hasMatch(digitsOnly);
}

/// Valida que un email tenga formato correcto
/// Input: String con email
/// Output: bool indicando si es válido
bool isValidEmail(String? email) {
  if (!isNotEmpty(email)) return false;
  return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email!);
}

/// Valida que una contraseña cumpla requisitos mínimos (8+ caracteres)
/// Input: String con contraseña
/// Output: bool indicando si es válida
bool isValidPassword(String? password) {
  if (!isNotEmpty(password)) return false;
  return password!.length >= 8;
}

/// Valida que un nombre tenga formato correcto (solo letras y espacios, 2+ chars)
/// Input: String con nombre
/// Output: bool indicando si es válido
bool isValidName(String? name) {
  if (!isNotEmpty(name)) return false;
  return name!.length >= 2 && RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(name);
}

/// Valida que dos campos coincidan (para confirmación de contraseña)
/// Input: Dos strings a comparar
/// Output: bool indicando si son iguales
bool fieldsMatch(String? field1, String? field2) {
  if (field1 == null || field2 == null) return false;
  return field1 == field2;
}

// ============================================================================
// FUNCIONES DE VALIDACIÓN CON MENSAJES (para TextFormField)
// ============================================================================

/// Valida teléfono y retorna mensaje de error si es inválido
/// Input: String? con teléfono
/// Output: String? con mensaje de error (null si es válido)
String? validatePhoneWithMessage(String? value) {
  if (!isNotEmpty(value)) {
    return 'Ingresa tu número de teléfono';
  }
  if (!isValidPhone(value)) {
    return 'Teléfono inválido. Debe tener 9 dígitos';
  }
  return null;
}

/// Valida código y retorna mensaje de error si es inválido
/// Input: String? con código
/// Output: String? con mensaje de error (null si es válido)
String? validateCodeWithMessage(String? value) {
  if (!isNotEmpty(value)) {
    return 'Ingresa el código de verificación';
  }
  if (!isValidVerificationCode(value)) {
    return 'Código inválido. Debe tener 6 dígitos';
  }
  return null;
}

/// Valida email y retorna mensaje de error si es inválido
/// Input: String? con email
/// Output: String? con mensaje de error (null si es válido)
String? validateEmailWithMessage(String? value) {
  if (!isNotEmpty(value)) {
    return 'Ingresa tu email';
  }
  if (!isValidEmail(value)) {
    return 'Email inválido';
  }
  return null;
}

/// Valida contraseña y retorna mensaje de error si es inválida
/// Input: String? con contraseña
/// Output: String? con mensaje de error (null si es válida)
String? validatePasswordWithMessage(String? value) {
  if (!isNotEmpty(value)) {
    return 'Ingresa tu contraseña';
  }
  if (!isValidPassword(value)) {
    return 'La contraseña debe tener al menos 8 caracteres';
  }
  return null;
}

/// Valida nombre y retorna mensaje de error si es inválido
/// Input: String? con nombre
/// Output: String? con mensaje de error (null si es válido)
String? validateNameWithMessage(String? value) {
  if (!isNotEmpty(value)) {
    return 'Ingresa tu nombre';
  }
  if (!isValidName(value)) {
    return 'Nombre inválido. Solo letras y espacios';
  }
  return null;
}

/// Valida confirmación de contraseña
/// Input: String? con contraseña original, String? con confirmación
/// Output: String? con mensaje de error (null si coinciden)
String? validatePasswordConfirmation(String? password, String? confirmation) {
  if (!isNotEmpty(confirmation)) {
    return 'Confirma tu contraseña';
  }
  if (!fieldsMatch(password, confirmation)) {
    return 'Las contraseñas no coinciden';
  }
  return null;
}

// ============================================================================
// FUNCIONES DE VALIDACIÓN DE FORMULARIOS COMPLETOS
// ============================================================================

/// Valida formulario de login completo
/// Input: String con teléfono
/// Output: Record con (isValid: bool, errors: Map<String, String>)
({bool isValid, Map<String, String> errors}) validateLoginForm(String phone) {
  final errors = <String, String>{};
  
  final phoneError = validatePhoneWithMessage(phone);
  if (phoneError != null) {
    errors['phone'] = phoneError;
  }
  
  return (isValid: errors.isEmpty, errors: errors);
}

/// Valida formulario de verificación completo
/// Input: String con código
/// Output: Record con (isValid: bool, errors: Map<String, String>)
({bool isValid, Map<String, String> errors}) validateVerificationForm(String code) {
  final errors = <String, String>{};
  
  final codeError = validateCodeWithMessage(code);
  if (codeError != null) {
    errors['code'] = codeError;
  }
  
  return (isValid: errors.isEmpty, errors: errors);
}

/// Valida formulario de registro completo
/// Input: Strings con nombre, email, teléfono, contraseña, confirmación
/// Output: Record con (isValid: bool, errors: Map<String, String>)
({bool isValid, Map<String, String> errors}) validateRegisterForm({
  required String name,
  required String email,
  required String phone,
  required String password,
  required String passwordConfirmation,
}) {
  final errors = <String, String>{};
  
  final nameError = validateNameWithMessage(name);
  if (nameError != null) errors['name'] = nameError;
  
  final emailError = validateEmailWithMessage(email);
  if (emailError != null) errors['email'] = emailError;
  
  final phoneError = validatePhoneWithMessage(phone);
  if (phoneError != null) errors['phone'] = phoneError;
  
  final passwordError = validatePasswordWithMessage(password);
  if (passwordError != null) errors['password'] = passwordError;
  
  final confirmError = validatePasswordConfirmation(password, passwordConfirmation);
  if (confirmError != null) errors['passwordConfirmation'] = confirmError;
  
  return (isValid: errors.isEmpty, errors: errors);
}
