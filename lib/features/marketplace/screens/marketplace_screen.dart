import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/models/module_template.dart';
import '../../../core/repositories/marketplace_repository.dart';
import '../../../core/repositories/module_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/module_display_utils.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/widgets/paper_background.dart';
import '../bloc/marketplace_bloc.dart';
import '../bloc/marketplace_event.dart';
import '../bloc/marketplace_state.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is AuthAuthenticated ? authState.user.uid : '';

    return BlocProvider(
      create: (context) => MarketplaceBloc(
        marketplaceRepository: context.read<MarketplaceRepository>(),
        moduleRepository: context.read<ModuleRepository>(),
        userId: userId,
      )..add(const MarketplaceStarted()),
      child: const _MarketplaceBody(),
    );
  }
}

class _MarketplaceBody extends StatelessWidget {
  const _MarketplaceBody();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.onBackground),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Marketplace',
          style: TextStyle(
            fontFamily: 'CormorantGaramond',
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: colors.onBackground,
          ),
        ),
      ),
      body: Stack(
        children: [
          PaperBackground(colors: colors),
          BlocBuilder<MarketplaceBloc, MarketplaceState>(
            builder: (context, state) {
              return switch (state) {
                MarketplaceInitial() ||
                MarketplaceLoading() =>
                  const Center(child: CircularProgressIndicator()),
                MarketplaceLoaded() => _LoadedContent(state: state),
                MarketplaceError(:final message) =>
                  Center(child: Text(message)),
              };
            },
          ),
        ],
      ),
    );
  }
}

class _LoadedContent extends StatelessWidget {
  final MarketplaceLoaded state;

  const _LoadedContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          sliver: SliverList.list(
            children: [
              const SizedBox(height: AppSpacing.md),
              _SearchBar(query: state.searchQuery),
              const SizedBox(height: AppSpacing.md),
              _CategoryChips(
                categories: state.categories,
                selected: state.selectedCategory,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
        if (state.filteredTemplates.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.light),
                    size: 48,
                    color: colors.onBackgroundMuted,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No templates found',
                    style: TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 16,
                      color: colors.onBackgroundMuted,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final template = state.filteredTemplates[index];
                  return _TemplateCard(
                    template: template,
                    isInstalling: state.installingId == template.id,
                    isInstalled: state.isInstalled(template.id),
                    onTap: () =>
                        context.push('/marketplace/${template.id}'),
                  );
                },
                childCount: state.filteredTemplates.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.85,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

// ─── Search Bar ───

class _SearchBar extends StatefulWidget {
  final String query;

  const _SearchBar({required this.query});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: TextField(
        controller: _controller,
        style: TextStyle(
          fontFamily: 'Karla',
          fontSize: 15,
          color: colors.onBackground,
        ),
        decoration: InputDecoration(
          hintText: 'Search templates...',
          hintStyle: TextStyle(
            fontFamily: 'Karla',
            fontSize: 15,
            color: colors.onBackgroundMuted,
          ),
          prefixIcon: Icon(
            PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.light),
            color: colors.onBackgroundMuted,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          context
              .read<MarketplaceBloc>()
              .add(MarketplaceSearchChanged(value));
        },
      ),
    );
  }
}

// ─── Category Chips ───

class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String? selected;

  const _CategoryChips({required this.categories, required this.selected});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _Chip(
            label: 'All',
            isSelected: selected == null,
            colors: colors,
            onTap: () => context
                .read<MarketplaceBloc>()
                .add(const MarketplaceCategoryChanged(null)),
          ),
          ...categories.map((category) => Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: _Chip(
                  label: category,
                  isSelected: selected == category,
                  colors: colors,
                  onTap: () => context
                      .read<MarketplaceBloc>()
                      .add(MarketplaceCategoryChanged(category)),
                ),
              )),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final AppColors colors;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.accent : colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? colors.accent : colors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Karla',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : colors.onBackground,
          ),
        ),
      ),
    );
  }
}

// ─── Template Card ───

class _TemplateCard extends StatelessWidget {
  final ModuleTemplate template;
  final bool isInstalling;
  final bool isInstalled;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.isInstalling,
    required this.isInstalled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final moduleColor = parseModuleColor(template.color);

    return GestureDetector(
      onTap: isInstalling ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: moduleColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    resolveModuleIcon(template.icon),
                    color: moduleColor,
                    size: 24,
                  ),
                ),
                const Spacer(),
                if (template.featured)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Featured',
                      style: TextStyle(
                        fontFamily: 'Karla',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: colors.accent,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              template.name,
              style: TextStyle(
                fontFamily: 'Karla',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.onBackground,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              template.description,
              style: TextStyle(
                fontFamily: 'Karla',
                fontSize: 12,
                color: colors.onBackgroundMuted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      template.category,
                      style: TextStyle(
                        fontFamily: 'Karla',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: colors.onBackgroundMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                if (isInstalled)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PhosphorIcons.checkCircle(PhosphorIconsStyle.bold),
                          size: 11,
                          color: colors.accent,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Installed',
                          style: TextStyle(
                            fontFamily: 'Karla',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: colors.accent,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (template.installCount > 0) ...[
                  Icon(
                    PhosphorIcons.downloadSimple(PhosphorIconsStyle.bold),
                    size: 12,
                    color: colors.onBackgroundMuted,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${template.installCount}',
                    style: TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 11,
                      color: colors.onBackgroundMuted,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
