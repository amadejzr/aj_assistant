import 'package:flutter/material.dart';

import 'blueprint_node.dart';
import '../engine/condition_evaluator.dart';
import 'render_context.dart';

import '../builders/layout/screen_builder.dart';
import '../builders/layout/tab_screen_builder.dart';
import '../builders/layout/form_screen_builder.dart';
import '../builders/layout/scroll_column_builder.dart';
import '../builders/layout/section_builder.dart';
import '../builders/layout/row_builder.dart';
import '../builders/layout/column_builder.dart';
import '../builders/layout/conditional_builder.dart';

import '../builders/display/stat_card_builder.dart';
import '../builders/display/entry_list_builder.dart';
import '../builders/display/entry_card_builder.dart';
import '../builders/display/text_display_builder.dart';
import '../builders/display/empty_state_builder.dart';
import '../builders/display/chart_builder.dart';
import '../builders/display/progress_bar_builder.dart';
import '../builders/display/date_calendar_builder.dart';
import '../builders/display/card_grid_builder.dart';
import '../builders/display/divider_builder.dart';

import '../builders/input/text_input_builder.dart';
import '../builders/input/number_input_builder.dart';
import '../builders/input/date_picker_builder.dart';
import '../builders/input/time_picker_builder.dart';
import '../builders/input/enum_selector_builder.dart';
import '../builders/input/toggle_builder.dart';
import '../builders/input/slider_builder.dart';
import '../builders/input/rating_input_builder.dart';
import '../builders/input/reference_picker_builder.dart';

import '../builders/action/button_builder.dart';
import '../builders/action/fab_builder.dart';
import '../builders/action/icon_button_builder.dart';
import '../builders/action/action_menu_builder.dart';
import '../builders/display/badge_builder.dart';
import '../builders/input/currency_input_builder.dart';
import '../builders/layout/expandable_builder.dart';

typedef WidgetBuilder = Widget Function(
  BlueprintNode node,
  RenderContext ctx,
);

class WidgetRegistry {
  WidgetRegistry._();
  static final instance = WidgetRegistry._();

  final Map<String, WidgetBuilder> _builders = {};

  void register(String type, WidgetBuilder builder) {
    _builders[type] = builder;
  }

  Widget build(BlueprintNode node, RenderContext ctx) {
    final context = {...ctx.screenParams, ...ctx.formValues};

    // Check `visible` condition before building any widget
    final visible = node.properties['visible'];
    if (visible != null) {
      if (!ConditionEvaluator.evaluate(visible, context)) {
        return const SizedBox.shrink();
      }
    }

    // Check `visibleWhen` condition (form field conditional visibility)
    final visibleWhen = node.properties['visibleWhen'];
    if (visibleWhen != null) {
      if (!ConditionEvaluator.evaluate(visibleWhen, context)) {
        return const SizedBox.shrink();
      }
    }

    final builder = _builders[node.type];
    if (builder == null) return const SizedBox.shrink();
    return builder(node, ctx);
  }

  void registerDefaults() {
    register('screen', buildScreen);
    register('tab_screen', buildTabScreen);
    register('form_screen', buildFormScreen);
    register('stat_card', buildStatCard);
    register('scroll_column', buildScrollColumn);
    register('section', buildSection);
    register('row', buildRow);
    register('column', buildColumnLayout);
    register('text_input', buildTextInput);
    register('number_input', buildNumberInput);
    register('date_picker', buildDatePicker);
    register('time_picker', buildTimePicker);
    register('enum_selector', buildEnumSelector);
    register('multi_enum_selector', buildEnumSelector);
    register('toggle', buildToggle);
    register('slider', buildSliderInput);
    register('rating_input', buildRatingInput);
    register('entry_list', buildEntryList);
    register('entry_card', buildEntryCard);
    register('text_display', buildTextDisplay);
    register('empty_state', buildEmptyState);
    register('button', buildButton);
    register('fab', buildFab);
    register('card_grid', buildCardGrid);
    register('date_calendar', buildDateCalendar);
    register('conditional', buildConditional);
    register('progress_bar', buildProgressBar);
    register('chart', buildChart);
    register('divider', buildDividerWidget);
    register('reference_picker', buildReferencePicker);
    register('currency_input', buildCurrencyInput);
    register('icon_button', buildIconButton);
    register('action_menu', buildActionMenu);
    register('badge', buildBadge);
    register('expandable', buildExpandable);
  }
}
