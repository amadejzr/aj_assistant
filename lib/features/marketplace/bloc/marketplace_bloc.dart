import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logging/log.dart';
import '../../../core/models/module_template.dart';
import '../../../core/repositories/marketplace_repository.dart';
import '../../../core/repositories/module_repository.dart';
import 'marketplace_event.dart';
import 'marketplace_state.dart';

const _tag = 'MarketplaceBloc';

class MarketplaceBloc extends Bloc<MarketplaceEvent, MarketplaceState> {
  final MarketplaceRepository marketplaceRepository;
  final ModuleRepository moduleRepository;
  final String userId;

  MarketplaceBloc({
    required this.marketplaceRepository,
    required this.moduleRepository,
    required this.userId,
  }) : super(const MarketplaceInitial()) {
    on<MarketplaceStarted>(_onStarted);
    on<MarketplaceCategoryChanged>(_onCategoryChanged);
    on<MarketplaceSearchChanged>(_onSearchChanged);
    on<MarketplaceTemplateInstalled>(_onInstalled);
  }

  Future<void> _onStarted(
    MarketplaceStarted event,
    Emitter<MarketplaceState> emit,
  ) async {
    emit(const MarketplaceLoading());

    try {
      final templates = await marketplaceRepository.getTemplates();
      final categories =
          templates.map((t) => t.category).toSet().toList()..sort();

      // Fetch user's installed modules to check which templates are already installed
      final userModules = await moduleRepository.watchModules(userId).first;
      final installedIds = userModules.map((m) => m.id).toSet();

      emit(MarketplaceLoaded(
        allTemplates: templates,
        filteredTemplates: templates,
        categories: categories,
        installedIds: installedIds,
      ));
    } catch (e) {
      Log.e('Failed to load templates', tag: _tag, error: e);
      emit(MarketplaceError(e.toString()));
    }
  }

  void _onCategoryChanged(
    MarketplaceCategoryChanged event,
    Emitter<MarketplaceState> emit,
  ) {
    final current = state;
    if (current is! MarketplaceLoaded) return;

    final updated = current.copyWith(
      selectedCategory: () => event.category,
    );

    emit(updated.copyWith(
      filteredTemplates: _filterTemplates(
        updated.allTemplates,
        event.category,
        updated.searchQuery,
      ),
    ));
  }

  void _onSearchChanged(
    MarketplaceSearchChanged event,
    Emitter<MarketplaceState> emit,
  ) {
    final current = state;
    if (current is! MarketplaceLoaded) return;

    final updated = current.copyWith(searchQuery: event.query);

    emit(updated.copyWith(
      filteredTemplates: _filterTemplates(
        updated.allTemplates,
        updated.selectedCategory,
        event.query,
      ),
    ));
  }

  Future<void> _onInstalled(
    MarketplaceTemplateInstalled event,
    Emitter<MarketplaceState> emit,
  ) async {
    final current = state;
    if (current is! MarketplaceLoaded) return;

    emit(current.copyWith(installingId: () => event.templateId));

    try {
      final template = current.allTemplates.firstWhere(
        (t) => t.id == event.templateId,
      );

      // Use template ID as module ID — prevents duplicates on re-install.
      final module = template.toModule(event.templateId);

      await moduleRepository.createModule(userId, module);
      await marketplaceRepository.incrementInstallCount(event.templateId);

      Log.i(
        'Installed template "${template.name}" as module ${event.templateId}',
        tag: _tag,
      );

      // Update install count locally
      final updatedTemplates = current.allTemplates.map((t) {
        if (t.id == event.templateId) {
          return ModuleTemplate(
            id: t.id,
            name: t.name,
            description: t.description,
            longDescription: t.longDescription,
            icon: t.icon,
            color: t.color,
            category: t.category,
            tags: t.tags,
            featured: t.featured,
            sortOrder: t.sortOrder,
            installCount: t.installCount + 1,
            version: t.version,
            schemas: t.schemas,
            screens: t.screens,
            settings: t.settings,
            guide: t.guide,
          );
        }
        return t;
      }).toList();

      final updated = current.copyWith(
        allTemplates: updatedTemplates,
        installingId: () => null,
        installedIds: {...current.installedIds, event.templateId},
      );

      emit(updated.copyWith(
        filteredTemplates: _filterTemplates(
          updatedTemplates,
          updated.selectedCategory,
          updated.searchQuery,
        ),
      ));
    } catch (e) {
      Log.e('Failed to install template', tag: _tag, error: e);
      emit(current.copyWith(installingId: () => null));
    }
  }

  List<ModuleTemplate> _filterTemplates(
    List<ModuleTemplate> templates,
    String? category,
    String query,
  ) {
    var filtered = templates;

    if (category != null) {
      filtered = filtered.where((t) => t.category == category).toList();
    }

    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      filtered = filtered.where((t) {
        return t.name.toLowerCase().contains(q) ||
            t.description.toLowerCase().contains(q) ||
            t.tags.any((tag) => tag.toLowerCase().contains(q));
      }).toList();
    }

    return filtered;
  }
}
