import 'package:flutter/material.dart';

import '../models/field_type.dart';
import '../../../core/theme/app_spacing.dart';

class FieldDraft {
  final TextEditingController keyController;
  final TextEditingController labelController;
  FieldType type;
  bool isRequired;
  List<String> options;
  String referenceSchemaKey;

  FieldDraft()
      : keyController = TextEditingController(),
        labelController = TextEditingController(),
        type = FieldType.text,
        isRequired = false,
        options = [],
        referenceSchemaKey = '';

  void dispose() {
    keyController.dispose();
    labelController.dispose();
  }
}

class FieldDraftRow extends StatelessWidget {
  final FieldDraft draft;
  final int index;
  final dynamic colors;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const FieldDraftRow({
    super.key,
    required this.draft,
    required this.index,
    required this.colors,
    required this.onRemove,
    required this.onChanged,
  });

  bool get _isEnumType =>
      draft.type == FieldType.enumType || draft.type == FieldType.multiEnum;

  bool get _isReference => draft.type == FieldType.reference;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with remove button
          Row(
            children: [
              Text(
                'Field ${index + 1}',
                style: TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.8,
                  color: colors.onBackgroundMuted,
                ),
              ),
              const Spacer(),
              IconButton(
                key: Key('remove_field_$index'),
                icon: Icon(Icons.close, size: 18, color: colors.error),
                onPressed: onRemove,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Key + Label row
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: Key('field_draft_key_$index'),
                  controller: draft.keyController,
                  style: TextStyle(color: colors.onBackground, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Key',
                    labelStyle: TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 12,
                      color: colors.onBackgroundMuted,
                    ),
                    filled: true,
                    fillColor: colors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  key: Key('field_draft_label_$index'),
                  controller: draft.labelController,
                  style: TextStyle(color: colors.onBackground, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Label',
                    labelStyle: TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 12,
                      color: colors.onBackgroundMuted,
                    ),
                    filled: true,
                    fillColor: colors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Type dropdown + Required toggle
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Type',
                    labelStyle: TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 12,
                      color: colors.onBackgroundMuted,
                    ),
                    filled: true,
                    fillColor: colors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<FieldType>(
                      key: Key('field_draft_type_$index'),
                      value: draft.type,
                      isExpanded: true,
                      dropdownColor: colors.surface,
                      style: TextStyle(
                          color: colors.onBackground, fontSize: 14),
                      items: FieldType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          draft.type = value;
                          onChanged();
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                children: [
                  Text(
                    'Req',
                    style: TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 11,
                      color: colors.onBackgroundMuted,
                    ),
                  ),
                  Switch(
                    key: Key('field_draft_required_$index'),
                    value: draft.isRequired,
                    activeTrackColor: colors.accentMuted,
                    activeThumbColor: colors.accent,
                    onChanged: (value) {
                      draft.isRequired = value;
                      onChanged();
                    },
                  ),
                ],
              ),
            ],
          ),
          // Enum options (inline chips)
          if (_isEnumType) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'OPTIONS',
              style: TextStyle(
                fontFamily: 'Karla',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.8,
                color: colors.onBackgroundMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...draft.options.asMap().entries.map((entry) {
                  return Chip(
                    label: Text(
                      entry.value,
                      style: TextStyle(
                        color: colors.onBackground,
                        fontSize: 13,
                      ),
                    ),
                    backgroundColor: colors.surface,
                    deleteIcon:
                        Icon(Icons.close, size: 14, color: colors.error),
                    onDeleted: () {
                      draft.options.removeAt(entry.key);
                      onChanged();
                    },
                  );
                }),
                _AddOptionChip(
                  colors: colors,
                  onAdd: (value) {
                    draft.options.add(value);
                    onChanged();
                  },
                ),
              ],
            ),
          ],
          // Reference schema key
          if (_isReference) ...[
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: Key('field_draft_ref_$index'),
              style: TextStyle(color: colors.onBackground, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Reference Schema Key',
                labelStyle: TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 12,
                  color: colors.onBackgroundMuted,
                ),
                filled: true,
                fillColor: colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
              ),
              onChanged: (value) {
                draft.referenceSchemaKey = value;
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _AddOptionChip extends StatefulWidget {
  final dynamic colors;
  final ValueChanged<String> onAdd;

  const _AddOptionChip({required this.colors, required this.onAdd});

  @override
  State<_AddOptionChip> createState() => _AddOptionChipState();
}

class _AddOptionChipState extends State<_AddOptionChip> {
  bool _editing = false;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_editing) {
      return SizedBox(
        width: 100,
        height: 32,
        child: TextField(
          controller: _controller,
          autofocus: true,
          style: TextStyle(color: widget.colors.onBackground, fontSize: 13),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            filled: true,
            fillColor: widget.colors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (value) {
            final trimmed = value.trim();
            if (trimmed.isNotEmpty) {
              widget.onAdd(trimmed);
            }
            _controller.clear();
            setState(() => _editing = false);
          },
        ),
      );
    }

    return ActionChip(
      label: Text(
        '+ Add',
        style: TextStyle(color: widget.colors.accent, fontSize: 13),
      ),
      backgroundColor: widget.colors.surface,
      side: BorderSide(color: widget.colors.accent.withValues(alpha: 0.3)),
      onPressed: () => setState(() => _editing = true),
    );
  }
}
