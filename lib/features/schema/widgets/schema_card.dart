import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/module_schema.dart';
import '../../../core/theme/app_spacing.dart';
import '../bloc/schema_bloc.dart';
import '../bloc/schema_event.dart';

class SchemaCard extends StatelessWidget {
  final String schemaKey;
  final ModuleSchema schema;
  final dynamic colors;

  const SchemaCard({
    super.key,
    required this.schemaKey,
    required this.schema,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final label = schema.label.isNotEmpty ? schema.label : schemaKey;
    final fieldCount = schema.fields.length;
    final fieldText = fieldCount == 1 ? '1 field' : '$fieldCount fields';

    return Card(
      color: colors.surface,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () {
          context.read<SchemaBloc>().add(
                SchemaScreenChanged(
                  'editor',
                  params: {'schemaKey': schemaKey},
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
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'CormorantGaramond',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: colors.onBackground,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      fieldText,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onBackgroundMuted,
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
        title: const Text('Delete Schema'),
        content: Text('Delete "$schemaKey" and all its fields?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<SchemaBloc>().add(
                    SchemaDeleted(schemaKey),
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
