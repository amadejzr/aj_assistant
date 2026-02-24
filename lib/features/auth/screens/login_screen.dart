import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late AnimationController _staggerController;

  late Animation<double> _sealScale;
  late Animation<double> _sealFade;
  late Animation<double> _headingSlide;
  late Animation<double> _headingFade;
  late Animation<double> _fieldSlide;
  late Animation<double> _fieldFade;
  late Animation<double> _buttonFade;

  @override
  void initState() {
    super.initState();

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
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

    // Name field
    _fieldSlide = Tween(begin: 14.0, end: 0.0).animate(CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.25, 0.55, curve: Curves.easeOutCubic),
    ));
    _fieldFade = CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.25, 0.47, curve: Curves.easeOut),
    );

    // Button
    _buttonFade = CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.4, 0.65, curve: Curves.easeOut),
    );

    _staggerController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          AuthLoginWithName(_nameController.text.trim()),
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
                              child: Text(
                                'What should we\ncall you?',
                                style: Theme.of(context)
                                    .textTheme
                                    .displayLarge,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),

                          // Name field
                          Transform.translate(
                            offset: Offset(0, _fieldSlide.value),
                            child: Opacity(
                              opacity: _fieldFade.value,
                              child: AuthTextField(
                                controller: _nameController,
                                label: 'Name',
                                hint: 'Your name or nickname',
                                textCapitalization:
                                    TextCapitalization.words,
                                style: AuthTextFieldStyle.login,
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().isEmpty) {
                                    return 'A name is required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // Continue button
                          Opacity(
                            opacity: _buttonFade.value,
                            child: BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, state) {
                                final isLoading = state is AuthLoading;
                                return SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed:
                                        isLoading ? null : _onContinue,
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
                                        : const Text('Continue'),
                                  ),
                                );
                              },
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
