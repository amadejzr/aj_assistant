import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/widgets/paper_background.dart';
import '../../renderer/blueprint_node.dart';
import '../../renderer/render_context.dart';
import '../../renderer/widget_registry.dart';

/// Renders a form screen with input fields, a submit button, and optional default values.
///
/// Blueprint JSON:
/// ```json
/// {"type": "form_screen", "title": "Add Entry", "submitLabel": "Save", "children": [{"type": "text_input", "fieldKey": "name"}]}
/// ```
///
/// - `title` (`String?`, optional): Title displayed in the app bar.
/// - `children` (`List<BlueprintNode>`, optional): Input widget nodes rendered inside the scrollable form body.
/// - `submitLabel` (`String`, optional): Label for the submit button. Defaults to `"Save"`.
/// - `editLabel` (`String?`, optional): Alternative submit button label used when editing an existing entry.
/// - `submitAction` (`Map<String, dynamic>`, optional): Action configuration dispatched on form submission.
/// - `defaults` (`Map<String, dynamic>`, optional): Default form field values merged with screen params.
/// - `nav` (`BlueprintNode?`, optional): An optional navigation widget rendered below the form fields.
Widget buildFormScreen(BlueprintNode node, RenderContext ctx) {
  final form = node as FormScreenNode;

  // Filter out meta keys (_entryId, etc.) from screenParams before merging
  // into form defaults — meta keys are for the bloc, not form data.
  final filteredParams = Map<String, dynamic>.fromEntries(
    ctx.screenParams.entries.where((e) => !e.key.startsWith('_')),
  );

  // In settings mode, seed form with current module settings
  final settingsDefaults = ctx.screenParams['_settingsMode'] == true
      ? Map<String, dynamic>.from(ctx.module.settings)
      : <String, dynamic>{};

  // Merge screenParams into defaults so navigated params auto-fill fields.
  final mergedDefaults = {...form.defaults, ...settingsDefaults, ...filteredParams};

  // If the form has defaults, inject them into the context so they get
  // included when the form is submitted.
  RenderContext effectiveCtx = ctx;
  if (mergedDefaults.isNotEmpty) {
    // Seed defaults into formValues for any keys not already set
    final seeded = Map<String, dynamic>.from(ctx.formValues);
    for (final entry in mergedDefaults.entries) {
      seeded.putIfAbsent(entry.key, () => entry.value);
    }

    effectiveCtx = RenderContext(
      module: ctx.module,
      entries: ctx.entries,
      allEntries: ctx.allEntries,
      formValues: seeded,
      screenParams: ctx.screenParams,
      canGoBack: ctx.canGoBack,
      onFormValueChanged: (key, value) {
        ctx.onFormValueChanged(key, value);
      },
      onFormSubmit: ctx.onFormSubmit,
      onNavigateToScreen: ctx.onNavigateToScreen,
      onNavigateBack: ctx.onNavigateBack,
      onDeleteEntry: ctx.onDeleteEntry,
      resolvedExpressions: ctx.resolvedExpressions,
      onCreateEntry: ctx.onCreateEntry,
      onUpdateEntry: ctx.onUpdateEntry,
      onScreenParamChanged: ctx.onScreenParamChanged,
    );
  }

  return _FormScreenShell(form: form, ctx: effectiveCtx);
}

class _FormScreenShell extends StatefulWidget {
  final FormScreenNode form;
  final RenderContext ctx;

  const _FormScreenShell({required this.form, required this.ctx});

  @override
  State<_FormScreenShell> createState() => _FormScreenShellState();
}

class _FormScreenShellState extends State<_FormScreenShell> {
  final _formKey = GlobalKey<FormState>();

  String get _effectiveSubmitLabel {
    final isEdit = widget.ctx.screenParams['_entryId'] != null;
    if (isEdit && widget.form.editLabel != null) {
      return widget.form.editLabel!;
    }
    return widget.form.submitLabel;
  }

  @override
  void initState() {
    super.initState();
    // Apply defaults + screenParams to BLoC on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Filter meta keys — they're for bloc navigation, not form data
      final filteredParams = Map<String, dynamic>.fromEntries(
        widget.ctx.screenParams.entries.where((e) => !e.key.startsWith('_')),
      );
      final mergedDefaults = {
        ...widget.form.defaults,
        ...filteredParams,
      };
      for (final entry in mergedDefaults.entries) {
        widget.ctx.onFormValueChanged(entry.key, entry.value);
      }
    });
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.ctx.onFormSubmit?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final registry = WidgetRegistry.instance;

    final canGoBack = widget.ctx.canGoBack;

    return PopScope(
      canPop: !canGoBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && canGoBack) {
          widget.ctx.onNavigateBack?.call();
        }
      },
      child: Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: canGoBack
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: colors.onBackground),
                onPressed: () => widget.ctx.onNavigateBack?.call(),
              )
            : null,
        title: widget.form.title != null
            ? Text(
                widget.form.title!,
                style: TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: colors.onBackground,
                ),
              )
            : null,
        iconTheme: IconThemeData(color: colors.onBackground),
      ),
      body: Stack(
        children: [
          PaperBackground(colors: colors),
          SafeArea(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final child in widget.form.children)
                            registry.build(child, widget.ctx),
                          // Nav widget (e.g. "Log Instead" / "Plan Instead")
                          if (widget.form.nav != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            registry.build(widget.form.nav!, widget.ctx),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.screenPadding),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: TextStyle(
                            fontFamily: 'Karla',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        child: Text(_effectiveSubmitLabel),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
