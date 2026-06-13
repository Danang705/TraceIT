import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../main/main_screen.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../utils/app_colors.dart';
import '../../../utils/custom_snackbar.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isObscure = true;
  String _password = '';

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
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

  void _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      CustomSnackBar.show(context, 'Nama, Email, dan Password wajib diisi', isError: true);
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

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.register(name, email, password, phone);
      
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      CustomSnackBar.show(context, e.toString().replaceAll('Exception: ', ''), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<AuthProvider>(context).isLoading;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.05),
              Colors.white,
              Colors.white,
            ],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo Top
                          Padding(
                            padding: const EdgeInsets.only(top: 20.0, bottom: 40.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/logo.png',
                                  height: 30,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.near_me, size: 24, color: AppColors.textPrimary),
                                        SizedBox(width: 8),
                                        Text(
                                          'TraceIt',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          
                          // Title & Subtitle
                          Text(
                            'Create Your TraceIt\nAccount',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Daftar sekarang untuk mulai melaporkan, melacak, dan menemukan barang hilang dengan mudah menggunakan TraceIt.',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Form Fields
                          AppTextField(
                            label: 'Nama Lengkap',
                            hint: 'Masukkan nama Anda',
                            controller: _nameController,
                            prefixIcon: const Icon(Icons.person_outline, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'Email',
                            hint: 'Masukkan email Anda',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'Nomor HP (Opsional)',
                            hint: '08xxxxxxxxxx',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'Password',
                            hint: 'Buat password',
                            controller: _passwordController,
                            obscureText: _isObscure,
                            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isObscure ? Icons.visibility_off : Icons.visibility,
                                color: AppColors.primary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isObscure = !_isObscure;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildPasswordCriteriaIndicator(),
                          
                          const Spacer(),
                          const SizedBox(height: 32),
                          
                          // Bottom Actions
                          AppButton(
                            text: 'Register',
                            isLoading: isLoading,
                            onPressed: _submit,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ', 
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  'Login',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
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
