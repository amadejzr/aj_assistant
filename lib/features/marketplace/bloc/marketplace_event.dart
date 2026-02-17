import 'package:equatable/equatable.dart';

sealed class MarketplaceEvent extends Equatable {
  const MarketplaceEvent();

  @override
  List<Object?> get props => [];
}

class MarketplaceStarted extends MarketplaceEvent {
  const MarketplaceStarted();
}

class MarketplaceCategoryChanged extends MarketplaceEvent {
  final String? category;

  const MarketplaceCategoryChanged(this.category);

  @override
  List<Object?> get props => [category];
}

class MarketplaceSearchChanged extends MarketplaceEvent {
  final String query;

  const MarketplaceSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class MarketplaceTemplateInstalled extends MarketplaceEvent {
  final String templateId;

  const MarketplaceTemplateInstalled(this.templateId);

  @override
  List<Object?> get props => [templateId];
}
