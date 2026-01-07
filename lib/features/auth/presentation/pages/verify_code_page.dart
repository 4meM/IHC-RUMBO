import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/rumbo_button.dart';
import '../controllers/auth_controller.dart';
import '../helpers/auth_validators.dart';
import '../helpers/text_formatters.dart';
import '../widgets/code_input_field.dart';
import '../widgets/auth_error_message.dart';

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
  final _controller = AuthController();

  @override
  void initState() {
    super.initState();
    _tryPasteCodeAutomatically();
  }

  Future<void> _tryPasteCodeAutomatically() async {
    final code = await _controller.tryPasteCode();
    if (code != null && mounted) {
      _codeController.text = code;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    if (_formKey.currentState!.validate()) {
      final success = await _controller.verifyCode(_codeController.text);
      
      if (success && mounted) {
        context.go('/home');
      }
    }
  }

  Future<void> _resendCode() async {
    final success = await _controller.resendVerificationCode();
    
    if (success && mounted) {
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
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            return SingleChildScrollView(
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
                      'Enviamos un código a +51 ${formatPhoneNumber(widget.phoneNumber)}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    CodeInputField(
                      controller: _codeController,
                      validator: validateCodeWithMessage,
                      enabled: !_controller.isLoading,
                    ),
                    
                    if (_controller.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      AuthErrorMessage(message: _controller.errorMessage!),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    RumboButton(
                      text: AppStrings.verifyButton,
                      onPressed: _controller.isLoading ? null : _verifyCode,
                      isLoading: _controller.isLoading,
                    ),
                    
                    const SizedBox(height: 16),
                    
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
            );
          },
        ),
      ),
    );
  }
}
