import 'package:flutter/material.dart';

import 'blueprint_node.dart';
import 'condition_evaluator.dart';
import 'render_context.dart';

import 'builders/screen_builder.dart';
import 'builders/tab_screen_builder.dart';
import 'builders/form_screen_builder.dart';
import 'builders/stat_card_builder.dart';
import 'builders/scroll_column_builder.dart';
import 'builders/section_builder.dart';
import 'builders/row_builder.dart';
import 'builders/column_builder.dart';
import 'builders/text_input_builder.dart';
import 'builders/number_input_builder.dart';
import 'builders/date_picker_builder.dart';
import 'builders/time_picker_builder.dart';
import 'builders/enum_selector_builder.dart';
import 'builders/toggle_builder.dart';
import 'builders/slider_builder.dart';
import 'builders/rating_input_builder.dart';
import 'builders/entry_list_builder.dart';
import 'builders/entry_card_builder.dart';
import 'builders/text_display_builder.dart';
import 'builders/empty_state_builder.dart';
import 'builders/button_builder.dart';
import 'builders/fab_builder.dart';
import 'builders/card_grid_builder.dart';
import 'builders/date_calendar_builder.dart';
import 'builders/conditional_builder.dart';
import 'builders/progress_bar_builder.dart';
import 'builders/chart_builder.dart';
import 'builders/divider_builder.dart';

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
    // Check `visible` condition before building any widget
    final visible = node.properties['visible'];
    if (visible != null) {
      final context = {...ctx.screenParams, ...ctx.formValues};
      if (!ConditionEvaluator.evaluate(visible, context)) {
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
  }
}
