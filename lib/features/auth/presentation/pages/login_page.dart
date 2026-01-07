import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/rumbo_button.dart';
import '../controllers/auth_controller.dart';
import '../helpers/auth_validators.dart';
import '../widgets/phone_input_field.dart';
import '../widgets/auth_logo.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _controller = AuthController();

  @override
  void dispose() {
    _phoneController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_formKey.currentState!.validate()) {
      final success = await _controller.sendVerificationCode(_phoneController.text);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Revisa tu bandeja de notificaciones'),
            backgroundColor: AppColors.success,
          ),
        );
        
        context.push('/verify-code', extra: _controller.phoneNumber);
      }
    }
  }

  void _continueWithoutAccount() {
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    
                    const AuthLogo(),
                    
                    const SizedBox(height: 60),
                    
                    PhoneInputField(
                      controller: _phoneController,
                      validator: validatePhoneWithMessage,
                      enabled: !_controller.isLoading,
                      hintText: AppStrings.phoneHint,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    RumboButton(
                      text: AppStrings.sendCodeButton,
                      onPressed: _controller.isLoading ? null : _sendCode,
                      isLoading: _controller.isLoading,
                    ),
                    
                    const SizedBox(height: 16),
                    
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
            );
          },
        ),
      ),
    );
  }
}
