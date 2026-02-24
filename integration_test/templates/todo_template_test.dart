import 'package:bowerlab/core/database/screen_query.dart';
import 'package:bowerlab/core/models/module_template.dart';
import 'package:bowerlab/core/repositories/templates/todo_template.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/module_test_helper.dart';

void main() {
  final harness = ModuleTestHarness();
  final templateJson = todoTemplate();
  final template = ModuleTemplate.fromJson('todo_list', templateJson);
  final module = template.toModule('test-todo-001');

  // ── Extract actual screen queries & mutations from the template ──

  final screens = templateJson['screens'] as Map<String, dynamic>;

  // Dashboard queries (main screen)
  final mainScreen = screens['main'] as Map<String, dynamic>;
  final mainQueries = mainScreen['queries'] as Map<String, dynamic>;
  final totalTasksQuery = ScreenQuery.fromJson(
    'total_tasks',
    mainQueries['total_tasks'] as Map<String, dynamic>,
  );
  final completedCountQuery = ScreenQuery.fromJson(
    'completed_count',
    mainQueries['completed_count'] as Map<String, dynamic>,
  );
  final pendingCountQuery = ScreenQuery.fromJson(
    'pending_count',
    mainQueries['pending_count'] as Map<String, dynamic>,
  );
  final progressQuery = ScreenQuery.fromJson(
    'progress',
    mainQueries['progress'] as Map<String, dynamic>,
  );
  final recentPendingQuery = ScreenQuery.fromJson(
    'recent_pending',
    mainQueries['recent_pending'] as Map<String, dynamic>,
  );

  // Pending screen query
  final pendingScreen = screens['pending'] as Map<String, dynamic>;
  final pendingQueries = pendingScreen['queries'] as Map<String, dynamic>;
  final pendingTodosQuery = ScreenQuery.fromJson(
    'pending_todos',
    pendingQueries['pending_todos'] as Map<String, dynamic>,
  );

  // Completed screen query
  final completedScreen = screens['completed'] as Map<String, dynamic>;
  final completedQueries = completedScreen['queries'] as Map<String, dynamic>;
  final completedTodosQuery = ScreenQuery.fromJson(
    'completed_todos',
    completedQueries['completed_todos'] as Map<String, dynamic>,
  );

  // Mutations from form screens
  final addScreen = screens['add_todo'] as Map<String, dynamic>;
  final addMutations = addScreen['mutations'] as Map<String, dynamic>;
  final createMutation = ScreenMutation.fromJson(addMutations['create']);

  final editScreen = screens['edit_todo'] as Map<String, dynamic>;
  final editMutations = editScreen['mutations'] as Map<String, dynamic>;
  final updateMutation = ScreenMutation.fromJson(editMutations['update']);

  final pendingMutations = pendingScreen['mutations'] as Map<String, dynamic>;
  final deleteMutation = ScreenMutation.fromJson(pendingMutations['delete']);

  setUp(() => harness.setUp(module));
  tearDown(() => harness.tearDown());

  // ── Schema ──

  group('schema', () {
    test('table and indexes created', () async {
      final tables = await harness.queryRows(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'm_todos'",
      );
      expect(tables, hasLength(1));

      final indexes = await harness.queryRows(
        "SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'idx_todos_%'",
      );
      expect(indexes, hasLength(3));
    });
  });

  // ── Create + verify data shows up in screen queries ──

  group('add todo and verify it appears', () {
    test('created todo appears in recent_pending with correct fields', () async {
      await harness.mutationExecutor.create(createMutation, {
        'title': 'Buy groceries',
        'note': 'Milk, eggs, bread',
        'priority': 'high',
        'status': 'pending',
        'due_date': '2026-03-01',
      });

      final rows =
          await harness.queryExecutor.execute(recentPendingQuery, {});
      expect(rows, hasLength(1));

      final todo = rows[0];
      expect(todo['id'], isNotEmpty);
      expect(todo['title'], 'Buy groceries');
      expect(todo['note'], 'Milk, eggs, bread');
      expect(todo['priority'], 'high');
      expect(todo['status'], 'pending');
      expect(todo['due_date'], '2026-03-01');
      expect(todo['completed_at'], isNull);
    });

    test('created todo appears in pending_todos with correct fields', () async {
      await harness.mutationExecutor.create(createMutation, {
        'title': 'Call dentist',
        'note': 'Schedule cleaning',
        'priority': 'low',
        'status': 'pending',
        'due_date': '2026-04-15',
      });

      final rows =
          await harness.queryExecutor.execute(pendingTodosQuery, {});
      expect(rows, hasLength(1));

      final todo = rows[0];
      expect(todo['title'], 'Call dentist');
      expect(todo['note'], 'Schedule cleaning');
      expect(todo['priority'], 'low');
      expect(todo['status'], 'pending');
      expect(todo['due_date'], '2026-04-15');
      expect(todo['completed_at'], isNull);
    });

    test('created todo updates dashboard stats', () async {
      // Empty state
      var total =
          await harness.queryExecutor.execute(totalTasksQuery, {});
      expect(total[0]['total'], 0);
      var progress =
          await harness.queryExecutor.execute(progressQuery, {});
      expect(progress[0]['done'], 0);
      expect(progress[0]['total'], 0);

      // Add one pending
      await harness.mutationExecutor.create(createMutation, {
        'title': 'First task',
        'priority': 'medium',
        'status': 'pending',
      });

      total = await harness.queryExecutor.execute(totalTasksQuery, {});
      expect(total[0]['total'], 1);
      var pending =
          await harness.queryExecutor.execute(pendingCountQuery, {});
      expect(pending[0]['total'], 1);
      var completed =
          await harness.queryExecutor.execute(completedCountQuery, {});
      expect(completed[0]['total'], 0);
      progress =
          await harness.queryExecutor.execute(progressQuery, {});
      expect(progress[0]['done'], 0);
      expect(progress[0]['total'], 1);

      // Add a second one
      await harness.mutationExecutor.create(createMutation, {
        'title': 'Second task',
        'priority': 'high',
        'status': 'pending',
      });

      total = await harness.queryExecutor.execute(totalTasksQuery, {});
      expect(total[0]['total'], 2);
      pending =
          await harness.queryExecutor.execute(pendingCountQuery, {});
      expect(pending[0]['total'], 2);
    });

    test('todo with no due_date still shows up', () async {
      await harness.mutationExecutor.create(createMutation, {
        'title': 'Someday task',
        'priority': 'low',
        'status': 'pending',
      });

      final rows =
          await harness.queryExecutor.execute(pendingTodosQuery, {});
      expect(rows, hasLength(1));
      expect(rows[0]['title'], 'Someday task');
      expect(rows[0]['due_date'], isNull);
    });

    test('multiple todos appear in correct order (due_date ASC, nulls last)',
        () async {
      await harness.mutationExecutor.create(createMutation, {
        'title': 'No date task',
        'priority': 'low',
        'status': 'pending',
      });
      await harness.mutationExecutor.create(createMutation, {
        'title': 'Later task',
        'priority': 'medium',
        'status': 'pending',
        'due_date': '2026-06-01',
      });
      await harness.mutationExecutor.create(createMutation, {
        'title': 'Soon task',
        'priority': 'high',
        'status': 'pending',
        'due_date': '2026-03-01',
      });

      final rows =
          await harness.queryExecutor.execute(pendingTodosQuery, {});
      expect(rows, hasLength(3));
      expect(rows[0]['title'], 'Soon task');
      expect(rows[0]['due_date'], '2026-03-01');
      expect(rows[1]['title'], 'Later task');
      expect(rows[1]['due_date'], '2026-06-01');
      expect(rows[2]['title'], 'No date task');
      expect(rows[2]['due_date'], isNull);
    });

    test('recent_pending limits to 5 results', () async {
      for (var i = 1; i <= 7; i++) {
        await harness.mutationExecutor.create(createMutation, {
          'title': 'Task $i',
          'priority': 'medium',
          'status': 'pending',
        });
      }

      final rows =
          await harness.queryExecutor.execute(recentPendingQuery, {});
      expect(rows, hasLength(5));
    });
  });

  // ── Update + verify data changes in screen queries ──

  group('update todo and verify changes', () {
    late String todoId;

    setUp(() async {
      todoId = await harness.mutationExecutor.create(createMutation, {
        'title': 'Original task',
        'note': 'Original note',
        'priority': 'medium',
        'status': 'pending',
        'due_date': '2026-05-01',
      });
    });

    test('editing title shows updated title in pending screen', () async {
      await harness.mutationExecutor.update(updateMutation, todoId, {
        'title': 'Renamed task',
      });

      final rows =
          await harness.queryExecutor.execute(pendingTodosQuery, {});
      expect(rows, hasLength(1));
      expect(rows[0]['title'], 'Renamed task');
      // Unchanged fields preserved
      expect(rows[0]['note'], 'Original note');
      expect(rows[0]['priority'], 'medium');
      expect(rows[0]['due_date'], '2026-05-01');
    });

    test('editing priority shows updated priority in pending screen', () async {
      await harness.mutationExecutor.update(updateMutation, todoId, {
        'priority': 'high',
      });

      final rows =
          await harness.queryExecutor.execute(pendingTodosQuery, {});
      expect(rows[0]['priority'], 'high');
      expect(rows[0]['title'], 'Original task'); // unchanged
    });

    test('completing moves todo from pending to completed screen', () async {
      // Starts in pending
      var pending =
          await harness.queryExecutor.execute(pendingTodosQuery, {});
      expect(pending, hasLength(1));
      expect(pending[0]['title'], 'Original task');

      var completed =
          await harness.queryExecutor.execute(completedTodosQuery, {});
      expect(completed, isEmpty);

      // Complete it
      await harness.mutationExecutor.update(updateMutation, todoId, {
        'status': 'completed',
      });

      // Now in completed, not in pending
      pending =
          await harness.queryExecutor.execute(pendingTodosQuery, {});
      expect(pending, isEmpty);

      completed =
          await harness.queryExecutor.execute(completedTodosQuery, {});
      expect(completed, hasLength(1));
      expect(completed[0]['title'], 'Original task');
      expect(completed[0]['note'], 'Original note');
      expect(completed[0]['priority'], 'medium');
      expect(completed[0]['status'], 'completed');
      expect(completed[0]['completed_at'], isNotNull);
    });

    test('completing updates dashboard progress', () async {
      var progress =
          await harness.queryExecutor.execute(progressQuery, {});
      expect(progress[0]['done'], 0);
      expect(progress[0]['total'], 1);

      await harness.mutationExecutor.update(updateMutation, todoId, {
        'status': 'completed',
      });

      progress =
          await harness.queryExecutor.execute(progressQuery, {});
      expect(progress[0]['done'], 1);
      expect(progress[0]['total'], 1);
    });

    test('un-completing moves todo back to pending screen', () async {
      // Complete then un-complete
      await harness.mutationExecutor.update(updateMutation, todoId, {
        'status': 'completed',
      });
      await harness.mutationExecutor.update(updateMutation, todoId, {
        'status': 'pending',
      });

      final pending =
          await harness.queryExecutor.execute(pendingTodosQuery, {});
      expect(pending, hasLength(1));
      expect(pending[0]['title'], 'Original task');
      expect(pending[0]['status'], 'pending');
      expect(pending[0]['completed_at'], isNull);

      final completed =
          await harness.queryExecutor.execute(completedTodosQuery, {});
      expect(completed, isEmpty);
    });
  });

  // ── Delete + verify data removed from screen queries ──

  group('delete todo and verify removal', () {
    test('deleted todo disappears from pending screen', () async {
      final id = await harness.mutationExecutor.create(createMutation, {
        'title': 'Will be removed',
        'priority': 'high',
        'status': 'pending',
        'due_date': '2026-03-01',
      });

      // Visible before
      var rows =
          await harness.queryExecutor.execute(pendingTodosQuery, {});
      expect(rows, hasLength(1));
      expect(rows[0]['title'], 'Will be removed');

      await harness.mutationExecutor.delete(deleteMutation, id);

      // Gone after
      rows = await harness.queryExecutor.execute(pendingTodosQuery, {});
      expect(rows, isEmpty);
    });

    test('deleted todo disappears from recent_pending', () async {
      final id = await harness.mutationExecutor.create(createMutation, {
        'title': 'Temporary',
        'priority': 'low',
        'status': 'pending',
      });

      var rows =
          await harness.queryExecutor.execute(recentPendingQuery, {});
      expect(rows, hasLength(1));

      await harness.mutationExecutor.delete(deleteMutation, id);

      rows = await harness.queryExecutor.execute(recentPendingQuery, {});
      expect(rows, isEmpty);
    });

    test('deleting one of many only removes that one', () async {
      await harness.mutationExecutor.create(createMutation, {
        'title': 'Keep me',
        'priority': 'high',
        'status': 'pending',
      });
      final deleteId = await harness.mutationExecutor.create(createMutation, {
        'title': 'Delete me',
        'priority': 'low',
        'status': 'pending',
      });
      await harness.mutationExecutor.create(createMutation, {
        'title': 'Keep me too',
        'priority': 'medium',
        'status': 'pending',
      });

      await harness.mutationExecutor.delete(deleteMutation, deleteId);

      final rows =
          await harness.queryExecutor.execute(pendingTodosQuery, {});
      expect(rows, hasLength(2));
      final titles = rows.map((r) => r['title']).toList();
      expect(titles, contains('Keep me'));
      expect(titles, contains('Keep me too'));
      expect(titles, isNot(contains('Delete me')));
    });

    test('deleting updates all dashboard stats', () async {
      final id = await harness.mutationExecutor.create(createMutation, {
        'title': 'About to go',
        'priority': 'medium',
        'status': 'pending',
      });

      var total =
          await harness.queryExecutor.execute(totalTasksQuery, {});
      expect(total[0]['total'], 1);
      var pending =
          await harness.queryExecutor.execute(pendingCountQuery, {});
      expect(pending[0]['total'], 1);

      await harness.mutationExecutor.delete(deleteMutation, id);

      total = await harness.queryExecutor.execute(totalTasksQuery, {});
      expect(total[0]['total'], 0);
      pending =
          await harness.queryExecutor.execute(pendingCountQuery, {});
      expect(pending[0]['total'], 0);
      final progress =
          await harness.queryExecutor.execute(progressQuery, {});
      expect(progress[0]['done'], 0);
      expect(progress[0]['total'], 0);
    });
  });

  // ── Teardown ──

  group('teardown', () {
    test('uninstallModule drops the table', () async {
      await harness.schemaManager.uninstallModule(module);

      final tables = await harness.queryRows(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'm_todos'",
      );
      expect(tables, isEmpty);
    });
  });
}
