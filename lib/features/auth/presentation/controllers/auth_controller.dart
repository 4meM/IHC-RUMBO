/// Controller para lógica de autenticación
/// Centraliza el estado y lógica de negocio para login y verificación
/// Estilo: Programación competitiva - cada método resuelve un problema específico

import 'package:flutter/material.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/clipboard_helper.dart';
import '../helpers/text_formatters.dart';
import '../helpers/auth_validators.dart';

/// Controller que maneja el estado de autenticación
class AuthController extends ChangeNotifier {
  // Estado
  bool _isLoading = false;
  String? _errorMessage;
  String? _phoneNumber;
  
  // Código mock para verificación
  static const String _mockVerificationCode = '123456';
  
  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get phoneNumber => _phoneNumber;
  
  /// Establece el estado de carga
  /// Input: bool indicando si está cargando
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  /// Establece un mensaje de error
  /// Input: String? con mensaje (null para limpiar)
  void setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }
  
  /// Limpia el mensaje de error
  void clearError() {
    setError(null);
  }
  
  /// Envía código de verificación por SMS
  /// Input: String con número de teléfono (sin formato)
  /// Output: Future<bool> indicando si fue exitoso
  Future<bool> sendVerificationCode(String phone) async {
    if (!isValidPhone(phone)) {
      setError('Número de teléfono inválido');
      return false;
    }
    
    setLoading(true);
    clearError();
    
    try {
      // Simular delay de red
      await Future.delayed(const Duration(seconds: 1));
      
      // Guardar teléfono
      _phoneNumber = removeHyphens(phone);
      
      // Enviar notificación simulando SMS
      await NotificationService().showSMSNotification(_mockVerificationCode);
      
      setLoading(false);
      return true;
    } catch (e) {
      setError('Error al enviar código. Intenta de nuevo.');
      setLoading(false);
      return false;
    }
  }
  
  /// Reenvía el código de verificación
  /// Output: Future<bool> indicando si fue exitoso
  Future<bool> resendVerificationCode() async {
    setLoading(true);
    clearError();
    
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      await NotificationService().showSMSNotification(_mockVerificationCode);
      
      setLoading(false);
      return true;
    } catch (e) {
      setError('Error al reenviar código');
      setLoading(false);
      return false;
    }
  }
  
  /// Verifica el código ingresado
  /// Input: String con código (con o sin formato)
  /// Output: Future<bool> indicando si el código es correcto
  Future<bool> verifyCode(String code) async {
    if (!isValidVerificationCode(code)) {
      setError('Código inválido. Debe tener 6 dígitos');
      return false;
    }
    
    setLoading(true);
    clearError();
    
    try {
      // Simular delay de red
      await Future.delayed(const Duration(seconds: 1));
      
      final codeWithoutFormat = removeHyphens(code);
      
      if (codeWithoutFormat == _mockVerificationCode) {
        setLoading(false);
        return true;
      } else {
        setError('Código incorrecto. Intenta de nuevo.');
        setLoading(false);
        return false;
      }
    } catch (e) {
      setError('Error al verificar código');
      setLoading(false);
      return false;
    }
  }
  
  /// Intenta pegar código automáticamente del portapapeles
  /// Output: Future<String?> con código si se encuentra en portapapeles
  Future<String?> tryPasteCode() async {
    try {
      final code = await pasteVerificationCode();
      return code;
    } catch (e) {
      return null;
    }
  }
  
  /// Resetea el controller al estado inicial
  void reset() {
    _isLoading = false;
    _errorMessage = null;
    _phoneNumber = null;
    notifyListeners();
  }
  
  /// Formatea el número de teléfono guardado para mostrar
  /// Output: String formateado "XXX-XXX-XXX" o vacío si no hay teléfono
  String getFormattedPhone() {
    if (_phoneNumber == null) return '';
    return formatPhoneNumber(_phoneNumber!);
  }
  
  /// Obtiene el número de teléfono con código de país
  /// Output: String "+51 XXX-XXX-XXX"
  String getPhoneWithCountryCode() {
    if (_phoneNumber == null) return '';
    return formatPhoneWithCountryCode(_phoneNumber!);
  }
}
