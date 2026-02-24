import '../../../features/blueprint/dsl/blueprint_dsl.dart';

Json todoTemplate() => TemplateDef.build(
  name: 'Todo List',
  description: 'Track tasks with priorities, due dates, and reminders',
  longDescription:
      'A simple but powerful todo list. Add tasks with priorities and due '
      'dates, set reminders so nothing slips through the cracks, and mark '
      'them done when you\'re finished. The dashboard shows your progress '
      'at a glance — how many tasks you\'ve knocked out and what\'s still '
      'on your plate.',
  icon: 'list-checks',
  color: '#3B82F6',
  category: 'Productivity',
  tags: ['todo', 'tasks', 'productivity', 'planner', 'reminders'],
  featured: true,
  sortOrder: 1,
  guide: [
    Guide.step(
      title: 'Add a Task',
      body: 'Tap + to create a task. Give it a title, set a priority, '
          'pick a due date, and optionally turn on a reminder so you '
          'don\'t forget.',
    ),
    Guide.step(
      title: 'Get It Done',
      body: 'Tap a task, change its status to completed, and hit Update.',
    ),
    Guide.step(
      title: 'Track Progress',
      body: 'The Dashboard shows your total tasks, how many are done, '
          'and a progress bar. The Pending and Done tabs let you focus '
          'on what matters.',
    ),
  ],

  // ─── Navigation ───
  navigation: Nav.bottomNav(items: [
    Nav.item(label: 'Dashboard', icon: 'list-checks', screenId: 'main'),
    Nav.item(label: 'Pending', icon: 'circle', screenId: 'pending'),
    Nav.item(label: 'Done', icon: 'check-circle', screenId: 'completed'),
  ]),

  // ─── Database ───
  database: Db.build(
    tableNames: {
      'todo': 'm_todos',
    },
    setup: [
      '''CREATE TABLE IF NOT EXISTS "m_todos" (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            note TEXT,
            priority TEXT NOT NULL DEFAULT 'medium',
            status TEXT NOT NULL DEFAULT 'pending',
            due_date TEXT,
            completed_at INTEGER,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )''',
      'CREATE INDEX IF NOT EXISTS "idx_todos_status" ON "m_todos" (status)',
      'CREATE INDEX IF NOT EXISTS "idx_todos_priority" ON "m_todos" (priority)',
      'CREATE INDEX IF NOT EXISTS "idx_todos_due_date" ON "m_todos" (due_date)',
    ],
    teardown: [
      'DROP TABLE IF EXISTS "m_todos"',
    ],
  ),

  // ─── Screens ───
  screens: {
    // ═══════════════════════════════════════════
    //  DASHBOARD
    // ═══════════════════════════════════════════
    'main': Layout.screen(
      appBar: Layout.appBar(title: 'Todo List', showBack: false),
      queries: {
        'total_tasks': Query.def(
          'SELECT COUNT(*) as total FROM "m_todos"',
        ),
        'completed_count': Query.def(
          'SELECT COUNT(*) as total FROM "m_todos" '
          'WHERE status = \'completed\'',
        ),
        'pending_count': Query.def(
          'SELECT COUNT(*) as total FROM "m_todos" '
          'WHERE status = \'pending\'',
        ),
        'progress': Query.def(
          'SELECT '
          'COUNT(CASE WHEN status = \'completed\' THEN 1 END) as done, '
          'COUNT(*) as total '
          'FROM "m_todos"',
        ),
        'recent_pending': Query.def(
          'SELECT id, title, note, priority, status, due_date, '
          'completed_at '
          'FROM "m_todos" '
          'WHERE status = \'pending\' '
          'ORDER BY CASE WHEN due_date IS NULL THEN 1 ELSE 0 END, '
          'due_date ASC LIMIT 5',
        ),
      },
      children: [
        Layout.scrollColumn(children: [
          Layout.row(children: [
            Display.statCard(
              label: 'Total',
              source: 'total_tasks',
              valueKey: 'total',
            ),
            Display.statCard(
              label: 'Completed',
              accent: true,
              source: 'completed_count',
              valueKey: 'total',
            ),
            Display.statCard(
              label: 'Pending',
              source: 'pending_count',
              valueKey: 'total',
            ),
          ]),
          Display.progressBar(
            label: 'Progress',
            source: 'progress',
            valueKey: 'done',
            maxKey: 'total',
            showPercentage: true,
          ),
          Display.entryList(
            title: 'Upcoming Tasks',
            source: 'recent_pending',
            emptyState: Display.emptyState(
              message: 'No pending tasks',
              icon: 'list-checks',
              action: Act.navigate('add_todo', label: 'Add your first task'),
            ),
            itemLayout: Display.entryCard(
              title: '{{title}}',
              subtitle: '{{priority}}',
              trailing: '{{due_date}}',
              onTap: Act.navigate(
                'edit_todo',
                forwardFields: [
                  'title', 'note', 'priority', 'status',
                  'due_date', 'completed_at',
                ],
                params: {},
              ),
            ),
          ),
        ]),
      ],
      fab: Actions.fab(
        icon: 'add',
        action: Act.navigate('add_todo', params: {}),
      ),
    ),

    // ═══════════════════════════════════════════
    //  PENDING — Tasks to do
    // ═══════════════════════════════════════════
    'pending': Layout.screen(
      appBar: Layout.appBar(title: 'Pending', showBack: false),
      queries: {
        'pending_todos': Query.def(
          'SELECT id, title, note, priority, status, due_date, '
          'completed_at '
          'FROM "m_todos" '
          'WHERE status = \'pending\' '
          'ORDER BY CASE WHEN due_date IS NULL THEN 1 ELSE 0 END, '
          'due_date ASC',
        ),
      },
      mutations: {
        'delete': Mut.sql('DELETE FROM "m_todos" WHERE id = :id'),
      },
      children: [
        Display.entryList(
          source: 'pending_todos',
          emptyState: Display.emptyState(
            message: 'All caught up!',
            icon: 'check-circle',
            action: Act.navigate('add_todo', label: 'Add a task'),
          ),
          itemLayout: Display.entryCard(
            title: '{{title}}',
            subtitle: '{{priority}}',
            trailing: '{{due_date}}',
            onTap: Act.navigate(
              'edit_todo',
              forwardFields: [
                'title', 'note', 'priority', 'status',
                'due_date', 'completed_at',
              ],
              params: {},
            ),
            swipeActions: {
              'right': Act.confirm(
                title: 'Delete Task',
                message: 'Remove this task?',
                onConfirm: Act.deleteEntry(),
              ),
            },
          ),
        ),
      ],
      fab: Actions.fab(
        icon: 'add',
        action: Act.navigate('add_todo', params: {}),
      ),
    ),

    // ═══════════════════════════════════════════
    //  COMPLETED — Done tasks
    // ═══════════════════════════════════════════
    'completed': Layout.screen(
      appBar: Layout.appBar(title: 'Done', showBack: false),
      queries: {
        'completed_todos': Query.def(
          'SELECT id, title, note, priority, status, due_date, '
          'completed_at '
          'FROM "m_todos" '
          'WHERE status = \'completed\' '
          'ORDER BY completed_at DESC',
        ),
      },
      mutations: {
        'delete': Mut.sql('DELETE FROM "m_todos" WHERE id = :id'),
      },
      children: [
        Display.entryList(
          source: 'completed_todos',
          emptyState: Display.emptyState(
            message: 'No completed tasks yet',
            icon: 'check-circle',
          ),
          itemLayout: Display.entryCard(
            title: '{{title}}',
            subtitle: '{{priority}}',
            onTap: Act.navigate(
              'edit_todo',
              forwardFields: [
                'title', 'note', 'priority', 'status',
                'due_date', 'completed_at',
              ],
              params: {},
            ),
            swipeActions: {
              'right': Act.confirm(
                title: 'Delete Task',
                message: 'Delete this completed task?',
                onConfirm: Act.deleteEntry(),
              ),
            },
          ),
        ),
      ],
    ),

    // ═══════════════════════════════════════════
    //  ADD TODO — Create a new task
    // ═══════════════════════════════════════════
    'add_todo': Layout.formScreen(
      title: 'Add Task',
      submitLabel: 'Save Task',
      defaults: {'status': 'pending', 'priority': 'medium'},
      mutations: {
        'create': Mut.sql(
          'INSERT INTO "m_todos" '
          '(id, title, note, priority, status, due_date, created_at, updated_at) '
          'VALUES (:id, :title, :note, :priority, :status, :due_date, :created_at, :updated_at)',
        ),
      },
      children: [
        Inputs.textInput(
          fieldKey: 'title', label: 'Title', required: true,
          validation: {'required': true, 'minLength': 1, 'message': 'Give your task a title'},
        ),
        Inputs.textInput(fieldKey: 'note', label: 'Note', multiline: true),
        Inputs.enumSelector(
          fieldKey: 'priority', label: 'Priority',
          options: ['low', 'medium', 'high'],
        ),
        Inputs.datePicker(fieldKey: 'due_date', label: 'Due Date'),
        Notifications.scheduleField(
          fieldKey: 'reminder',
          label: 'Remind me',
          titleTemplate: 'Todo: {{title}}',
          messageTemplate: 'Don\'t forget: {{title}}',
        ),
      ],
    ),

    // ═══════════════════════════════════════════
    //  EDIT TODO — View, edit, and complete
    // ═══════════════════════════════════════════
    'edit_todo': Layout.formScreen(
      title: 'Edit Task',
      editLabel: 'Update',
      mutations: {
        'update': Mut.sql(
          'UPDATE "m_todos" SET '
          'title = COALESCE(:title, title), '
          'note = COALESCE(:note, note), '
          'priority = COALESCE(:priority, priority), '
          'status = COALESCE(:status, status), '
          'due_date = COALESCE(:due_date, due_date), '
          'completed_at = CASE '
          '  WHEN :status = \'completed\' AND completed_at IS NULL THEN :updated_at '
          '  WHEN :status = \'pending\' THEN NULL '
          '  ELSE completed_at '
          'END, '
          'updated_at = :updated_at '
          'WHERE id = :id',
        ),
      },
      children: [
        Inputs.textInput(
          fieldKey: 'title', label: 'Title', required: true,
          validation: {'required': true, 'minLength': 1, 'message': 'Give your task a title'},
        ),
        Inputs.textInput(fieldKey: 'note', label: 'Note', multiline: true),
        Inputs.enumSelector(
          fieldKey: 'priority', label: 'Priority',
          options: ['low', 'medium', 'high'],
        ),
        Inputs.enumSelector(
          fieldKey: 'status', label: 'Status',
          options: ['pending', 'completed'],
        ),
        Inputs.datePicker(fieldKey: 'due_date', label: 'Due Date'),
        Notifications.scheduleField(
          fieldKey: 'reminder',
          label: 'Remind me',
          titleTemplate: 'Todo: {{title}}',
          messageTemplate: 'Don\'t forget: {{title}}',
        ),
      ],
    ),
  },
);
