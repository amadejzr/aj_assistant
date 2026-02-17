import 'package:equatable/equatable.dart';

import '../../../core/models/module_template.dart';

sealed class MarketplaceState extends Equatable {
  const MarketplaceState();

  @override
  List<Object?> get props => [];
}

class MarketplaceInitial extends MarketplaceState {
  const MarketplaceInitial();
}

class MarketplaceLoading extends MarketplaceState {
  const MarketplaceLoading();
}

class MarketplaceLoaded extends MarketplaceState {
  final List<ModuleTemplate> allTemplates;
  final List<ModuleTemplate> filteredTemplates;
  final List<String> categories;
  final String? selectedCategory;
  final String searchQuery;
  final String? installingId;
  final Set<String> installedIds;

  const MarketplaceLoaded({
    required this.allTemplates,
    required this.filteredTemplates,
    required this.categories,
    this.selectedCategory,
    this.searchQuery = '',
    this.installingId,
    this.installedIds = const {},
  });

  bool isInstalled(String templateId) => installedIds.contains(templateId);

  MarketplaceLoaded copyWith({
    List<ModuleTemplate>? allTemplates,
    List<ModuleTemplate>? filteredTemplates,
    List<String>? categories,
    String? Function()? selectedCategory,
    String? searchQuery,
    String? Function()? installingId,
    Set<String>? installedIds,
  }) {
    return MarketplaceLoaded(
      allTemplates: allTemplates ?? this.allTemplates,
      filteredTemplates: filteredTemplates ?? this.filteredTemplates,
      categories: categories ?? this.categories,
      selectedCategory:
          selectedCategory != null ? selectedCategory() : this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      installingId:
          installingId != null ? installingId() : this.installingId,
      installedIds: installedIds ?? this.installedIds,
    );
  }

  @override
  List<Object?> get props => [
        allTemplates,
        filteredTemplates,
        categories,
        selectedCategory,
        searchQuery,
        installingId,
        installedIds,
      ];
}

class MarketplaceError extends MarketplaceState {
  final String message;

  const MarketplaceError(this.message);

  @override
  List<Object?> get props => [message];
}
