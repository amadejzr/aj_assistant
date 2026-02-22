import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../renderer/blueprint_node.dart';
import '../../renderer/render_context.dart';

/// Renders a currency form field with a prefix symbol, decimal formatting on blur, and numeric input.
///
/// Blueprint JSON:
/// ```json
/// {"type": "currency_input", "fieldKey": "amount", "currencySymbol": "$", "decimalPlaces": 2}
/// ```
///
/// - `fieldKey` (`String`, required): Schema field key this input is bound to.
/// - `currencySymbol` (`String`, optional): Currency symbol displayed as a prefix. Defaults to `"$"`.
/// - `decimalPlaces` (`int`, optional): Number of decimal places shown on blur. Defaults to `2`.
Widget buildCurrencyInput(BlueprintNode node, RenderContext ctx) {
  final input = node as CurrencyInputNode;
  return _CurrencyInputWidget(input: input, ctx: ctx);
}

class _CurrencyInputWidget extends StatefulWidget {
  final CurrencyInputNode input;
  final RenderContext ctx;

  const _CurrencyInputWidget({required this.input, required this.ctx});

  @override
  State<_CurrencyInputWidget> createState() => _CurrencyInputWidgetState();
}

class _CurrencyInputWidgetState extends State<_CurrencyInputWidget> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final current = widget.ctx.getFormValue(widget.input.fieldKey);
    _controller = TextEditingController(
      text: current != null ? _formatDisplay(current) : '',
    );
    _focusNode.addListener(_onFocusChange);
  }

  String _formatDisplay(dynamic value) {
    final num = double.tryParse(value.toString());
    if (num == null) return value.toString();
    return num.toStringAsFixed(widget.input.decimalPlaces);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      // Format on blur
      final raw = _controller.text.replaceAll(RegExp(r'[^0-9.]'), '');
      final num = double.tryParse(raw);
      if (num != null) {
        _controller.text = _formatDisplay(num);
        widget.ctx.onFormValueChanged(widget.input.fieldKey, num);
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final meta = widget.ctx.resolveFieldMeta(
      widget.input.fieldKey,
      widget.input.properties,
    );
    final label = meta.label;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Karla',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colors.onBackgroundMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            style: TextStyle(
              fontFamily: 'Karla',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: colors.onBackground,
            ),
            decoration: InputDecoration(
              prefixText: '${widget.input.currencySymbol} ',
              prefixStyle: TextStyle(
                fontFamily: 'Karla',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.onBackground,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            validator: (value) {
              if (meta.required && (value == null || value.isEmpty)) {
                return '$label is required';
              }
              return null;
            },
            onChanged: (value) {
              final raw = value.replaceAll(RegExp(r'[^0-9.]'), '');
              final num = double.tryParse(raw);
              if (num != null) {
                widget.ctx.onFormValueChanged(widget.input.fieldKey, num);
              }
            },
          ),
        ],
      ),
    );
  }
}
