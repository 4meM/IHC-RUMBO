import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/widgets/rumbo_button.dart';

class CodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('-', '');
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

class VerifyCodePage extends StatefulWidget {
  final String phoneNumber;
  
  const VerifyCodePage({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<VerifyCodePage> createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  
  // Código mock hardcodeado
  static const String _mockCode = '123456';

  @override
  void initState() {
    super.initState();
    // Intentar pegar el código del portapapeles automáticamente
    _pasteCodeFromClipboard();
  }

  Future<void> _pasteCodeFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData != null && clipboardData.text != null) {
        final text = clipboardData.text!.trim();
        // Verificar que sea un código de 6 dígitos (con o sin guión)
        final digitsOnly = text.replaceAll('-', '');
        if (RegExp(r'^\d{6}$').hasMatch(digitsOnly)) {
          setState(() {
            _codeController.text = text;
          });
        }
      }
    } catch (e) {
      // Ignorar errores de portapapeles
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String _formatPhoneNumber(String phone) {
    if (phone.length != 9) return phone;
    return '${phone.substring(0, 3)}-${phone.substring(3, 6)}-${phone.substring(6, 9)}';
  }

  void _verifyCode() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      // Simular delay de red
      Future.delayed(const Duration(seconds: 1), () {
        final enteredCode = _codeController.text.replaceAll('-', '');
        
        if (enteredCode == _mockCode) {
          // Código correcto, navegar al home
          context.go('/home');
        } else {
          // Código incorrecto
          setState(() {
            _isLoading = false;
            _errorMessage = 'Código incorrecto. Intenta de nuevo.';
          });
        }
      });
    }
  }

  void _resendCode() async {
    await NotificationService().showSMSNotification('123456');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código reenviado. Revisa notificaciones'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.verifyCodeTitle,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enviamos un código a +51 ${_formatPhoneNumber(widget.phoneNumber)}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Input de código
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                    CodeFormatter(),
                  ],
                  decoration: InputDecoration(
                    hintText: '000-000',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.error),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppStrings.codeRequired;
                    }
                    final digitsOnly = value.replaceAll('-', '');
                    if (digitsOnly.length != 6) {
                      return AppStrings.codeInvalid;
                    }
                    return null;
                  },
                ),
                
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 32),
                
                // Botón verificar
                RumboButton(
                  text: AppStrings.verifyButton,
                  onPressed: _isLoading ? null : _verifyCode,
                  isLoading: _isLoading,
                ),
                
                const SizedBox(height: 16),
                
                // Botón reenviar código
                Center(
                  child: TextButton(
                    onPressed: _resendCode,
                    child: const Text(
                      AppStrings.resendCode,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
