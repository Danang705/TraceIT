import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../utils/app_colors.dart';
import '../../../utils/custom_snackbar.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String resetToken;

  const ResetPasswordScreen({Key? key, required this.resetToken}) : super(key: key);

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isObscure = true;
  bool _isConfirmObscure = true;
  String _password = '';

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    setState(() {
      _password = _passwordController.text;
    });
  }

  bool _validatePasswordLength(String password) {
    return password.length >= 8;
  }

  bool _validatePasswordComplexity(String password) {
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasLower = RegExp(r'[a-z]').hasMatch(password);
    final hasDigit = RegExp(r'[0-9]').hasMatch(password);
    final count = (hasUpper ? 1 : 0) + (hasLower ? 1 : 0) + (hasDigit ? 1 : 0);
    return count >= 2;
  }

  void _resetPassword() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.isEmpty || confirmPassword.isEmpty) {
      CustomSnackBar.show(context, 'Password dan konfirmasi password wajib diisi', isError: true);
      return;
    }

    if (!_validatePasswordLength(password)) {
      CustomSnackBar.show(context, 'Password harus minimal 8 karakter', isError: true);
      return;
    }

    if (!_validatePasswordComplexity(password)) {
      CustomSnackBar.show(
        context, 
        'Password wajib menggabungkan minimal 2 unsur: Huruf besar (A-Z), Huruf kecil (a-z), atau Angka (0-9)', 
        isError: true
      );
      return;
    }

    if (password != confirmPassword) {
      CustomSnackBar.show(context, 'Konfirmasi password tidak cocok', isError: true);
      return;
    }

    setState(() { _isLoading = true; });

    try {
      await _authService.resetPassword(widget.resetToken, password);
      if (mounted) {
        CustomSnackBar.show(context, 'Password berhasil diubah. Silakan Login.', isError: false);
        // Navigate to Login Screen and clear routing stack
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Password Baru',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Masukkan kata sandi baru Anda untuk memperbarui akun.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 32),
              AppTextField(
                label: 'Password Baru',
                hint: 'Masukkan password baru',
                controller: _passwordController,
                obscureText: _isObscure,
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isObscure ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => setState(() => _isObscure = !_isObscure),
                ),
              ),
              const SizedBox(height: 12),
              _buildPasswordCriteriaIndicator(),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Konfirmasi Password Baru',
                hint: 'Masukkan ulang password baru',
                controller: _confirmPasswordController,
                obscureText: _isConfirmObscure,
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmObscure ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => setState(() => _isConfirmObscure = !_isConfirmObscure),
                ),
              ),
              const SizedBox(height: 32),
              AppButton(
                text: 'Simpan Password Baru',
                isLoading: _isLoading,
                onPressed: _resetPassword,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordCriteriaIndicator() {
    final hasMinLength = _validatePasswordLength(_password);
    final hasComplexity = _validatePasswordComplexity(_password);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kriteria Keamanan Password:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _buildCriteriaRow('Minimal 8 karakter', hasMinLength),
          const SizedBox(height: 4),
          _buildCriteriaRow('Menggabungkan minimal 2 unsur: Huruf Besar, Huruf Kecil, atau Angka', hasComplexity),
        ],
      ),
    );
  }

  Widget _buildCriteriaRow(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isMet ? AppColors.success : AppColors.textSecondary.withOpacity(0.5),
          size: 14,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isMet ? AppColors.success : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
