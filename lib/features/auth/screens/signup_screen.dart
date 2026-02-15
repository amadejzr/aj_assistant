import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onSignUp() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthSignUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      body: AuthErrorListener(
        child: Stack(
          children: [
            PaperBackground(colors: colors),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: AppSpacing.xxl),
                          // Vermillion seal — matching login
                          Align(
                            alignment: Alignment.centerLeft,
                            child: SealLogo(
                              color: colors.accent,
                              textColor: colors.background,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'Create account',
                            style: Theme.of(context).textTheme.displayLarge,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Start building your personal assistant',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.xxl),

                          // Name field
                          AuthTextField(
                            controller: _nameController,
                            label: 'Display name',
                            hint: 'How should we call you?',
                            style: AuthTextFieldStyle.signup,
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Email field
                          AuthTextField(
                            controller: _emailController,
                            label: 'Email',
                            hint: 'you@example.com',
                            keyboardType: TextInputType.emailAddress,
                            style: AuthTextFieldStyle.signup,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!value.contains('@')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Password field
                          AuthTextField(
                            controller: _passwordController,
                            label: 'Password',
                            hint: 'At least 6 characters',
                            obscureText: _obscurePassword,
                            style: AuthTextFieldStyle.signup,
                            suffixIcon: PasswordVisibilityToggle(
                              obscured: _obscurePassword,
                              onToggle: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // Create Account button
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              final isLoading = state is AuthLoading;
                              return SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _onSignUp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colors.accent,
                                    foregroundColor: colors.background,
                                    disabledBackgroundColor: colors.accentMuted,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    textStyle: GoogleFonts.dmSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  child: isLoading
                                      ? SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: colors.background,
                                          ),
                                        )
                                      : const Text('Create Account'),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Sign in link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              GestureDetector(
                                onTap: () => context.go('/login'),
                                child: Text(
                                  'Sign in',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: colors.accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
