import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/widgets/rumbo_button.dart';

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('-', '');
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

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _sendCode() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      // Remover guiones del número
      final phoneNumber = _phoneController.text.replaceAll('-', '');
      
      // Simular delay de envío
      Future.delayed(const Duration(seconds: 1), () async {
        setState(() => _isLoading = false);
        
        // Enviar notificación simulando SMS
        await NotificationService().showSMSNotification('123456');
        
        // Mostrar mensaje de éxito
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Revisa tu bandeja de notificaciones'),
              backgroundColor: AppColors.success,
            ),
          );
          
          // Navegar a página de verificación
          context.push('/verify-code', extra: phoneNumber);
        }
      });
    }
  }

  void _continueWithoutAccount() {
    // TODO: Navegar al home sin autenticación
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 60),
                
                // Logo placeholder
                _buildLogo(),
                
                const SizedBox(height: 60),
                
                // Input de teléfono
                _buildPhoneInput(),
                
                const SizedBox(height: 24),
                
                // Botón recibir código
                RumboButton(
                  text: AppStrings.sendCodeButton,
                  onPressed: _isLoading ? null : _sendCode,
                  isLoading: _isLoading,
                ),
                
                const SizedBox(height: 16),
                
                // Botón continuar sin cuenta
                OutlinedButton(
                  onPressed: _continueWithoutAccount,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Text(
                    AppStrings.continueWithoutAccountButton,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
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

  Widget _buildLogo() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.directions_bus_rounded,
          size: 80,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Código de país
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            children: [
              Icon(Icons.flag, size: 20),
              SizedBox(width: 8),
              Text(
                '+51',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Campo de teléfono
        Expanded(
          child: TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(9),
              PhoneNumberFormatter(),
            ],
            decoration: InputDecoration(
              hintText: AppStrings.phoneHint,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.error),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppStrings.phoneRequired;
              }
              final digitsOnly = value.replaceAll('-', '');
              if (digitsOnly.length != 9) {
                return AppStrings.phoneInvalid;
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}
