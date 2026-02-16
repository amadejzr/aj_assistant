import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/field_definition.dart';
import '../../../core/theme/app_spacing.dart';
import '../bloc/schema_bloc.dart';
import '../bloc/schema_event.dart';

class FieldCard extends StatelessWidget {
  final String schemaKey;
  final String fieldKey;
  final FieldDefinition field;
  final dynamic colors;

  const FieldCard({
    super.key,
    required this.schemaKey,
    required this.fieldKey,
    required this.field,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: colors.surface,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () {
          context.read<SchemaBloc>().add(
                SchemaScreenChanged(
                  'field_editor',
                  params: {
                    'schemaKey': schemaKey,
                    'fieldKey': fieldKey,
                  },
                ),
              );
        },
        onLongPress: () => _showDeleteDialog(context),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          field.label,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colors.onBackground,
                          ),
                        ),
                        if (field.required) ...[
                          const SizedBox(width: 4),
                          Text(
                            '*',
                            style: TextStyle(
                              color: colors.accent,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        field.type.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onBackgroundMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colors.onBackgroundMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Field'),
        content: Text('Delete field "$fieldKey"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<SchemaBloc>().add(
                    FieldDeleted(schemaKey, fieldKey),
                  );
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
