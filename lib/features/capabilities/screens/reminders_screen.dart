import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/widgets/paper_background.dart';
import '../bloc/capabilities_bloc.dart';
import '../bloc/capabilities_event.dart';
import '../bloc/capabilities_state.dart';
import '../models/capability.dart';
import '../repositories/capability_repository.dart';
import '../services/notification_scheduler.dart';
import '../widgets/add_reminder_sheet.dart';
import '../widgets/capability_card.dart';

class RemindersScreen extends StatelessWidget {
  final String? moduleId;

  const RemindersScreen({super.key, this.moduleId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CapabilitiesBloc(
        capabilityRepository: context.read<CapabilityRepository>(),
        notificationScheduler: context.read<NotificationScheduler>(),
      )..add(CapabilitiesStarted(moduleId: moduleId)),
      child: _RemindersBody(moduleId: moduleId),
    );
  }
}

class _RemindersBody extends StatelessWidget {
  final String? moduleId;

  const _RemindersBody({this.moduleId});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Stack(
      children: [
        PaperBackground(colors: colors),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              moduleId != null ? 'Module Reminders' : 'Reminders',
              style: TextStyle(
                fontFamily: 'CormorantGaramond',
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: colors.onBackground,
              ),
            ),
            leading: IconButton(
              icon: Icon(
                PhosphorIcons.caretLeft(PhosphorIconsStyle.bold),
                color: colors.onBackground,
              ),
              onPressed: () => context.pop(),
            ),
          ),
          body: BlocBuilder<CapabilitiesBloc, CapabilitiesState>(
            builder: (context, state) {
              return switch (state) {
                CapabilitiesInitial() ||
                CapabilitiesLoading() =>
                  const Center(child: CircularProgressIndicator()),
                CapabilitiesError(:final message) => Center(
                    child: Text(
                      message,
                      style: TextStyle(
                        fontFamily: 'Karla',
                        fontSize: 14,
                        color: colors.error,
                      ),
                    ),
                  ),
                CapabilitiesLoaded(:final capabilities) => capabilities.isEmpty
                    ? _buildEmptyState(colors)
                    : _buildGroupedList(context, capabilities),
              };
            },
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: colors.accent,
            onPressed: () {
              final bloc = context.read<CapabilitiesBloc>();
              showAddReminderSheet(
                context,
                moduleId: moduleId,
                bloc: bloc,
              );
            },
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(dynamic colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIcons.bellSlash(PhosphorIconsStyle.light),
            size: 56,
            color: colors.onBackgroundMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No reminders yet',
            style: TextStyle(
              fontFamily: 'Karla',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.onBackgroundMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tap + to create your first reminder',
            style: TextStyle(
              fontFamily: 'Karla',
              fontSize: 13,
              color: colors.onBackgroundMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList(
    BuildContext context,
    List<Capability> capabilities,
  ) {
    final colors = context.colors;

    // Group capabilities by moduleId
    final grouped = <String?, List<Capability>>{};
    for (final cap in capabilities) {
      grouped.putIfAbsent(cap.moduleId, () => []).add(cap);
    }

    // Sort groups: null (General) first, then by moduleId
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        if (a == null) return -1;
        if (b == null) return 1;
        return a.compareTo(b);
      });

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: sortedKeys.length,
      itemBuilder: (context, groupIndex) {
        final key = sortedKeys[groupIndex];
        final items = grouped[key]!;
        final groupLabel = key ?? 'General';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (groupIndex > 0) const SizedBox(height: AppSpacing.lg),
            // Group header
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                groupLabel,
                style: TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.onBackgroundMuted,
                ),
              ),
            ),
            // Reminder cards
            ...items.map((cap) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Dismissible(
                    key: ValueKey(cap.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) {
                      context
                          .read<CapabilitiesBloc>()
                          .add(CapabilityDeleted(cap.id));
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding:
                          const EdgeInsets.only(right: AppSpacing.screenPadding),
                      decoration: BoxDecoration(
                        color: colors.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        PhosphorIcons.trash(PhosphorIconsStyle.bold),
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    child: CapabilityCard(
                      capability: cap,
                      onTap: () {
                        if (cap is ScheduledReminder) {
                          final bloc = context.read<CapabilitiesBloc>();
                          showAddReminderSheet(
                            context,
                            existing: cap,
                            bloc: bloc,
                          );
                        }
                      },
                      onToggle: (enabled) {
                        context.read<CapabilitiesBloc>().add(
                              CapabilityToggled(cap.id, enabled: enabled),
                            );
                      },
                    ),
                  ),
                )),
          ],
        );
      },
    );
  }
}
