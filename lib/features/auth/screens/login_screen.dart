import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  late AnimationController _staggerController;

  late Animation<double> _sealScale;
  late Animation<double> _sealFade;
  late Animation<double> _headingSlide;
  late Animation<double> _headingFade;
  late Animation<double> _emailSlide;
  late Animation<double> _emailFade;
  late Animation<double> _passwordSlide;
  late Animation<double> _passwordFade;
  late Animation<double> _buttonFade;
  late Animation<double> _linkFade;

  @override
  void initState() {
    super.initState();

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Seal stamps in with a scale bounce
    _sealScale = Tween(begin: 1.4, end: 1.0).animate(CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOutBack),
    ));
    _sealFade = CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.0, 0.15, curve: Curves.easeOut),
    );

    // Heading fades up
    _headingSlide = Tween(begin: 14.0, end: 0.0).animate(CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.12, 0.4, curve: Curves.easeOutCubic),
    ));
    _headingFade = CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.12, 0.32, curve: Curves.easeOut),
    );

    // Email
    _emailSlide = Tween(begin: 14.0, end: 0.0).animate(CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.22, 0.52, curve: Curves.easeOutCubic),
    ));
    _emailFade = CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.22, 0.44, curve: Curves.easeOut),
    );

    // Password
    _passwordSlide = Tween(begin: 14.0, end: 0.0).animate(CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.32, 0.6, curve: Curves.easeOutCubic),
    ));
    _passwordFade = CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.32, 0.52, curve: Curves.easeOut),
    );

    // Button
    _buttonFade = CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.42, 0.65, curve: Curves.easeOut),
    );

    // Link
    _linkFade = CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.5, 0.75, curve: Curves.easeOut),
    );

    _staggerController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  void _onSignIn() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          AuthLoginWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
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
                  child: Form(
                    key: _formKey,
                    child: AnimatedBuilder(
                      animation: _staggerController,
                      builder: (context, _) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: AppSpacing.xxl),

                          // Vermillion seal — like a hanko stamp
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Transform.scale(
                              scale: _sealScale.value,
                              child: Opacity(
                                opacity: _sealFade.value,
                                child: SealLogo(
                                  color: colors.accent,
                                  textColor: colors.background,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Heading
                          Transform.translate(
                            offset: Offset(0, _headingSlide.value),
                            child: Opacity(
                              opacity: _headingFade.value,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome back',
                                    style: Theme.of(context)
                                        .textTheme
                                        .displayLarge,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Sign in to continue',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),

                          // Email
                          Transform.translate(
                            offset: Offset(0, _emailSlide.value),
                            child: Opacity(
                              opacity: _emailFade.value,
                              child: AuthTextField(
                                controller: _emailController,
                                label: 'Email',
                                hint: 'you@example.com',
                                keyboardType: TextInputType.emailAddress,
                                style: AuthTextFieldStyle.login,
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().isEmpty) {
                                    return 'Email is required';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Password
                          Transform.translate(
                            offset: Offset(0, _passwordSlide.value),
                            child: Opacity(
                              opacity: _passwordFade.value,
                              child: AuthTextField(
                                controller: _passwordController,
                                label: 'Password',
                                hint:
                                    '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
                                obscureText: _obscurePassword,
                                style: AuthTextFieldStyle.login,
                                suffixIcon: PasswordVisibilityToggle(
                                  obscured: _obscurePassword,
                                  onToggle: () => setState(
                                    () =>
                                        _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Password is required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // Sign In button
                          Opacity(
                            opacity: _buttonFade.value,
                            child: BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, state) {
                                final isLoading = state is AuthLoading;
                                return SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed:
                                        isLoading ? null : _onSignIn,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colors.accent,
                                      foregroundColor: colors.background,
                                      disabledBackgroundColor:
                                          colors.accentMuted,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      elevation: 0,
                                      textStyle: TextStyle(
                                        fontFamily: 'Karla',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    child: isLoading
                                        ? SizedBox(
                                            width: 22,
                                            height: 22,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: colors.background,
                                            ),
                                          )
                                        : const Text('Sign In'),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Sign up link
                          Opacity(
                            opacity: _linkFade.value,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium,
                                ),
                                GestureDetector(
                                  onTap: () => context.go('/signup'),
                                  child: Text(
                                    'Sign up',
                                    style: TextStyle(
                                      fontFamily: 'Karla',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: colors.accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
