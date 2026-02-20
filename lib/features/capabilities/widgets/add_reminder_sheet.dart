import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/module.dart';
import '../../../core/repositories/module_repository.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/capabilities_bloc.dart';
import '../bloc/capabilities_event.dart';
import '../models/capability.dart';

Future<void> showAddReminderSheet(
  BuildContext context, {
  String? moduleId,
  required CapabilitiesBloc bloc,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: _AddReminderSheet(moduleId: moduleId),
    ),
  );
}

class _AddReminderSheet extends StatefulWidget {
  final String? moduleId;

  const _AddReminderSheet({this.moduleId});

  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  ReminderFrequency _frequency = ReminderFrequency.daily;
  TimeOfDay _time = TimeOfDay.now();
  int _dayOfWeek = 1; // Monday
  int _dayOfMonth = 1;
  String? _selectedModuleId;
  List<Module> _modules = [];

  @override
  void initState() {
    super.initState();
    _selectedModuleId = widget.moduleId;
    _loadModules();
  }

  Future<void> _loadModules() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final modules = await context
        .read<ModuleRepository>()
        .watchModules(authState.user.uid)
        .first;
    if (mounted) {
      setState(() => _modules = modules);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.lg,
        AppSpacing.screenPadding,
        AppSpacing.lg + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.onBackgroundMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Title
            Text(
              'New Reminder',
              style: TextStyle(
                fontFamily: 'CormorantGaramond',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colors.onBackground,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Title field
            _label('TITLE', colors),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _titleController,
              style: TextStyle(
                fontFamily: 'Karla',
                fontSize: 14,
                color: colors.onBackground,
              ),
              decoration: const InputDecoration(
                hintText: 'Reminder title',
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Message field
            _label('MESSAGE', colors),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _messageController,
              style: TextStyle(
                fontFamily: 'Karla',
                fontSize: 14,
                color: colors.onBackground,
              ),
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Notification message',
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Module picker
            _label('MODULE', colors),
            const SizedBox(height: AppSpacing.xs),
            DropdownButtonFormField<String?>(
              initialValue: _selectedModuleId,
              dropdownColor: colors.surface,
              style: TextStyle(
                fontFamily: 'Karla',
                fontSize: 14,
                color: colors.onBackground,
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.border),
                ),
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(
                    'General (no module)',
                    style: TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 14,
                      color: colors.onBackgroundMuted,
                    ),
                  ),
                ),
                ..._modules.map(
                  (m) => DropdownMenuItem<String?>(
                    value: m.id,
                    child: Text(m.name),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedModuleId = value);
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Frequency
            _label('FREQUENCY', colors),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ReminderFrequency>(
                segments: const [
                  ButtonSegment(
                    value: ReminderFrequency.daily,
                    label: Text('Daily'),
                  ),
                  ButtonSegment(
                    value: ReminderFrequency.weekly,
                    label: Text('Weekly'),
                  ),
                  ButtonSegment(
                    value: ReminderFrequency.monthly,
                    label: Text('Monthly'),
                  ),
                ],
                selected: {_frequency},
                onSelectionChanged: (values) {
                  setState(() => _frequency = values.first);
                },
                style: ButtonStyle(
                  textStyle: WidgetStatePropertyAll(
                    TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 13,
                      color: colors.onBackground,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Time picker
            _label('TIME', colors),
            const SizedBox(height: AppSpacing.xs),
            GestureDetector(
              onTap: _pickTime,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 18,
                      color: colors.onBackgroundMuted,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      _time.format(context),
                      style: TextStyle(
                        fontFamily: 'Karla',
                        fontSize: 14,
                        color: colors.onBackground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Day of week (weekly only)
            if (_frequency == ReminderFrequency.weekly) ...[
              _label('DAY OF WEEK', colors),
              const SizedBox(height: AppSpacing.xs),
              DropdownButtonFormField<int>(
                initialValue: _dayOfWeek,
                dropdownColor: colors.surface,
                style: TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 14,
                  color: colors.onBackground,
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Monday')),
                  DropdownMenuItem(value: 2, child: Text('Tuesday')),
                  DropdownMenuItem(value: 3, child: Text('Wednesday')),
                  DropdownMenuItem(value: 4, child: Text('Thursday')),
                  DropdownMenuItem(value: 5, child: Text('Friday')),
                  DropdownMenuItem(value: 6, child: Text('Saturday')),
                  DropdownMenuItem(value: 7, child: Text('Sunday')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _dayOfWeek = value);
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Day of month (monthly only)
            if (_frequency == ReminderFrequency.monthly) ...[
              _label('DAY OF MONTH', colors),
              const SizedBox(height: AppSpacing.xs),
              DropdownButtonFormField<int>(
                initialValue: _dayOfMonth,
                dropdownColor: colors.surface,
                style: TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 14,
                  color: colors.onBackground,
                ),
                items: List.generate(
                  28,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text('${i + 1}'),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) setState(() => _dayOfMonth = value);
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            const SizedBox(height: AppSpacing.sm),

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Karla',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Save Reminder'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, dynamic colors) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Karla',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: colors.onBackgroundMuted,
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  void _save() {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (title.isEmpty || message.isEmpty) return;

    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch.toString();

    final reminder = ScheduledReminder(
      id: id,
      moduleId: _selectedModuleId,
      title: title,
      message: message,
      enabled: true,
      createdAt: now,
      updatedAt: now,
      frequency: _frequency,
      hour: _time.hour,
      minute: _time.minute,
      dayOfWeek: _frequency == ReminderFrequency.weekly ? _dayOfWeek : null,
      dayOfMonth: _frequency == ReminderFrequency.monthly ? _dayOfMonth : null,
    );

    context.read<CapabilitiesBloc>().add(CapabilityCreated(reminder));
    Navigator.of(context).pop();
  }
}
