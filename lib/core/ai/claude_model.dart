enum ClaudeModel {
  opus('claude-opus-4-6', 'Opus', 'Most capable'),
  sonnet('claude-sonnet-4-6', 'Sonnet', 'Balanced'),
  haiku('claude-haiku-4-5-20251001', 'Haiku', 'Fast & light');

  final String apiId;
  final String label;
  final String description;
  const ClaudeModel(this.apiId, this.label, this.description);
}
