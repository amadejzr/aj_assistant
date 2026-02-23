// lib/features/settings/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/ai/api_key_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../auth/widgets/paper_background.dart';
import '../cubit/theme_cubit.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final _apiKeyController = TextEditingController();
  bool _obscureKey = true;
  bool _hasExistingKey = false;
  bool _isDirty = false;
  bool _isSaving = false;

  late final AnimationController _animController;
  late final Animation<double> _titleFade;
  late final Animation<double> _titleSlide;
  late final Animation<double> _section1Fade;
  late final Animation<double> _section1Slide;
  late final Animation<double> _section2Fade;
  late final Animation<double> _section2Slide;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _titleFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _titleSlide = Tween(begin: 14.0, end: 0.0).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
    ));

    _section1Fade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.15, 0.55, curve: Curves.easeOut),
    );
    _section1Slide = Tween(begin: 14.0, end: 0.0).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.15, 0.55, curve: Curves.easeOutCubic),
    ));

    _section2Fade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
    );
    _section2Slide = Tween(begin: 14.0, end: 0.0).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
    ));

    _animController.forward();
    _loadApiKey();

    _apiKeyController.addListener(() {
      final dirty = _apiKeyController.text.isNotEmpty;
      if (dirty != _isDirty) setState(() => _isDirty = dirty);
    });
  }

  Future<void> _loadApiKey() async {
    final service = context.read<ApiKeyService>();
    final key = await service.getKey();
    if (key != null && key.isNotEmpty && mounted) {
      setState(() {
        _hasExistingKey = true;
        _apiKeyController.text = key;
        _isDirty = false;
      });
    }
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) return;

    if (!key.startsWith('sk-ant-')) {
      AppToast.show(
        context,
        message: 'API key should start with sk-ant-',
        type: AppToastType.error,
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await context.read<ApiKeyService>().setKey(key);
      if (mounted) {
        setState(() {
          _hasExistingKey = true;
          _isDirty = false;
          _isSaving = false;
        });
        AppToast.show(
          context,
          message: 'API key saved',
          type: AppToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppToast.show(
          context,
          message: 'Failed to save API key',
          type: AppToastType.error,
        );
      }
    }
  }

  Future<void> _deleteApiKey() async {
    await context.read<ApiKeyService>().deleteKey();
    if (mounted) {
      setState(() {
        _apiKeyController.clear();
        _hasExistingKey = false;
        _isDirty = false;
      });
      AppToast.show(
        context,
        message: 'API key removed',
        type: AppToastType.info,
      );
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      body: Stack(
        children: [
          PaperBackground(colors: colors),
          SafeArea(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    _buildBackButton(colors),
                    const SizedBox(height: AppSpacing.lg),
                    _buildTitle(context),
                    const SizedBox(height: AppSpacing.xxl),
                    _buildApiKeySection(colors),
                    const SizedBox(height: AppSpacing.xl),
                    _buildThemeSection(colors),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(AppColors colors) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: () => context.pop(),
        icon: Icon(
          PhosphorIcons.arrowLeft(PhosphorIconsStyle.light),
          color: colors.onBackgroundMuted,
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, _titleSlide.value),
      child: Opacity(
        opacity: _titleFade.value,
        child: Text(
          'Settings',
          style: Theme.of(context).textTheme.displayLarge,
        ),
      ),
    );
  }

  Widget _buildApiKeySection(AppColors colors) {
    return Transform.translate(
      offset: Offset(0, _section1Slide.value),
      child: Opacity(
        opacity: _section1Fade.value,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(colors, 'AI Provider'),
            const SizedBox(height: AppSpacing.md),
            _buildApiKeyField(colors),
            const SizedBox(height: AppSpacing.md),
            _buildApiKeyActions(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(AppColors colors, String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontFamily: 'Karla',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: colors.onBackgroundMuted,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildApiKeyField(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Anthropic API Key',
              style: TextStyle(
                fontFamily: 'Karla',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colors.onBackground,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (_hasExistingKey)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colors.success,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _apiKeyController,
          obscureText: _obscureKey,
          cursorColor: colors.accent,
          style: TextStyle(
            fontFamily: 'Karla',
            fontSize: 15,
            color: colors.onBackground,
          ),
          decoration: InputDecoration(
            hintText: 'sk-ant-api03-...',
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscureKey = !_obscureKey),
              icon: Icon(
                _obscureKey
                    ? PhosphorIcons.eye(PhosphorIconsStyle.light)
                    : PhosphorIcons.eyeSlash(PhosphorIconsStyle.light),
                color: colors.onBackgroundMuted,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApiKeyActions(AppColors colors) {
    return Row(
      children: [
        if (_isDirty)
          Expanded(
            child: SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveApiKey,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: colors.background,
                  disabledBackgroundColor: colors.accentMuted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                  textStyle: const TextStyle(
                    fontFamily: 'Karla',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: _isSaving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.background,
                        ),
                      )
                    : const Text('Save Key'),
              ),
            ),
          ),
        if (_isDirty && _hasExistingKey) const SizedBox(width: AppSpacing.sm),
        if (_hasExistingKey)
          SizedBox(
            height: 44,
            child: OutlinedButton(
              onPressed: _deleteApiKey,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.error,
                side: BorderSide(color: colors.error.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Remove'),
            ),
          ),
      ],
    );
  }

  Widget _buildThemeSection(AppColors colors) {
    return Transform.translate(
      offset: Offset(0, _section2Slide.value),
      child: Opacity(
        opacity: _section2Fade.value,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(colors, 'Appearance'),
            const SizedBox(height: AppSpacing.md),
            _buildThemeToggle(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle(AppColors colors) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, currentMode) {
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              for (final mode in ThemeMode.values)
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        context.read<ThemeCubit>().setTheme(mode),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: mode == currentMode
                            ? colors.accent
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        switch (mode) {
                          ThemeMode.system => 'System',
                          ThemeMode.light => 'Light',
                          ThemeMode.dark => 'Dark',
                        },
                        style: TextStyle(
                          fontFamily: 'Karla',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: mode == currentMode
                              ? colors.background
                              : colors.onBackgroundMuted,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
