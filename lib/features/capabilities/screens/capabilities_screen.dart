import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import '../widgets/capability_card.dart';

class CapabilitiesScreen extends StatelessWidget {
  final String moduleId;

  const CapabilitiesScreen({super.key, required this.moduleId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CapabilitiesBloc(
        capabilityRepository: context.read<CapabilityRepository>(),
        notificationScheduler: context.read<NotificationScheduler>(),
      )..add(CapabilitiesStarted(moduleId: moduleId)),
      child: const _CapabilitiesBody(),
    );
  }
}

class _CapabilitiesBody extends StatelessWidget {
  const _CapabilitiesBody();

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
              'Reminders & Alerts',
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
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: BlocBuilder<CapabilitiesBloc, CapabilitiesState>(
            builder: (context, state) {
              return switch (state) {
                CapabilitiesInitial() ||
                CapabilitiesLoading() =>
                  const Center(child: CircularProgressIndicator()),
                CapabilitiesError(:final message) =>
                  Center(child: Text(message)),
                CapabilitiesLoaded(:final capabilities) =>
                  capabilities.isEmpty
                      ? _buildEmptyState(colors)
                      : _buildList(context, capabilities),
              };
            },
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
            'Set up reminders to stay on track',
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

  Widget _buildList(BuildContext context, List<Capability> capabilities) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: capabilities.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final cap = capabilities[index];
        return CapabilityCard(
          capability: cap,
          onToggle: (enabled) {
            context.read<CapabilitiesBloc>().add(
              CapabilityToggled(cap.id, enabled: enabled),
            );
          },
        );
      },
    );
  }
}
