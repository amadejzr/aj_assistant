import '../../lib/features/blueprint/dsl/blueprint_dsl.dart';

Json hikingTemplate() => TemplateDef.build(
  name: 'Hiking Journal',
  description: 'Plan hikes, track completions, and rate your adventures',
  longDescription:
      'Your personal hiking planner and journal. Add upcoming hikes with '
      'an optional date, then mark them done when you\'ve conquered the trail. '
      'Rate each completed hike and jot down your thoughts — over time you\'ll '
      'build a journal of every adventure with stats to match.',
  icon: 'mountains',
  color: '#4E7A51',
  category: 'Health & Fitness',
  tags: ['hiking', 'outdoors', 'fitness', 'nature', 'journal', 'adventure'],
  featured: true,
  sortOrder: 2,
  guide: [
    Guide.step(
      title: 'Plan a Hike',
      body: 'Tap + to add a hike. Give it a name, pick a trail or location, '
          'and optionally set a date. No date? It\'ll sit in your planned list '
          'until you\'re ready.',
    ),
    Guide.step(
      title: 'Hit the Trail',
      body: 'When you finish a hike, open it and tap "Mark Complete". '
          'Rate it 1–5 stars and add any notes about the experience.',
    ),
    Guide.step(
      title: 'Look Back',
      body: 'The Completed tab shows every hike you\'ve done with your '
          'ratings. The Dashboard tracks your total hikes and average rating.',
    ),
  ],

  // ─── Navigation ───
  navigation: Nav.bottomNav(items: [
    Nav.item(label: 'Dashboard', icon: 'chart-line-up', screenId: 'main'),
    Nav.item(label: 'Planned', icon: 'map-trifold', screenId: 'planned'),
    Nav.item(label: 'Completed', icon: 'check-circle', screenId: 'completed'),
  ]),

  // ─── Database ───
  database: Db.build(
    tableNames: {
      'hike': 'm_hikes',
    },
    setup: [
      '''CREATE TABLE IF NOT EXISTS "m_hikes" (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            location TEXT,
            date INTEGER,
            difficulty TEXT NOT NULL DEFAULT 'Moderate',
            distance_km REAL,
            status TEXT NOT NULL DEFAULT 'Planned',
            rating INTEGER,
            notes TEXT,
            completed_at INTEGER,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )''',
      'CREATE INDEX IF NOT EXISTS "idx_hikes_status" ON "m_hikes" (status)',
      'CREATE INDEX IF NOT EXISTS "idx_hikes_date" ON "m_hikes" (date)',
      'CREATE INDEX IF NOT EXISTS "idx_hikes_completed" ON "m_hikes" (completed_at)',
    ],
    teardown: [
      'DROP TABLE IF EXISTS "m_hikes"',
    ],
  ),

  // ─── Screens ───
  screens: {
    // ═══════════════════════════════════════════
    //  DASHBOARD
    // ═══════════════════════════════════════════
    'main': Layout.screen(
      appBar: Layout.appBar(title: 'Hiking Journal', showBack: false),
      queries: {
        'total_hikes': Query.def(
          'SELECT COUNT(*) as total FROM "m_hikes" '
          'WHERE status = \'Completed\'',
        ),
        'planned_count': Query.def(
          'SELECT COUNT(*) as total FROM "m_hikes" '
          'WHERE status = \'Planned\'',
        ),
        'avg_rating': Query.def(
          'SELECT COALESCE(ROUND(AVG(rating), 1), 0) as avg '
          'FROM "m_hikes" WHERE status = \'Completed\' AND rating IS NOT NULL',
        ),
        'recent': Query.def(
          'SELECT id, name, location, date, difficulty, distance_km, '
          'status, rating, notes, completed_at '
          'FROM "m_hikes" '
          'WHERE status = \'Completed\' '
          'ORDER BY completed_at DESC LIMIT 5',
        ),
      },
      children: [
        Layout.scrollColumn(children: [
          Layout.row(children: [
            Display.statCard(
              label: 'Hikes Done',
              accent: true,
              source: 'total_hikes',
              valueKey: 'total',
            ),
            Display.statCard(
              label: 'Planned',
              source: 'planned_count',
              valueKey: 'total',
            ),
          ]),
          Layout.row(children: [
            Display.statCard(
              label: 'Avg Rating',
              source: 'avg_rating',
              valueKey: 'avg',
            ),
          ]),
          Display.entryList(
            title: 'Recent Completions',
            source: 'recent',
            emptyState: Display.emptyState(
              message: 'No completed hikes yet',
              icon: 'mountains',
              action: Act.navigate('add_hike', label: 'Plan your first hike'),
            ),
            itemLayout: Display.entryCard(
              title: '{{name}}',
              subtitle: '{{location}}',
              trailing: '{{rating}}',
              onTap: Act.navigate(
                'view_hike',
                forwardFields: [
                  'name', 'location', 'date', 'difficulty',
                  'distance_km', 'status', 'rating', 'notes', 'completed_at',
                ],
                params: {},
              ),
            ),
          ),
        ]),
      ],
      fab: Actions.fab(
        icon: 'add',
        action: Act.navigate('add_hike', params: {}),
      ),
    ),

    // ═══════════════════════════════════════════
    //  PLANNED — Upcoming hikes
    // ═══════════════════════════════════════════
    'planned': Layout.screen(
      appBar: Layout.appBar(title: 'Planned', showBack: false),
      queries: {
        'planned_hikes': Query.def(
          'SELECT id, name, location, date, difficulty, distance_km, '
          'status, rating, notes, completed_at '
          'FROM "m_hikes" '
          'WHERE status = \'Planned\' '
          'ORDER BY CASE WHEN date IS NULL THEN 1 ELSE 0 END, date ASC',
        ),
      },
      mutations: {
        'delete': Mut.sql('DELETE FROM "m_hikes" WHERE id = :id'),
      },
      children: [
        Display.entryList(
          source: 'planned_hikes',
          emptyState: Display.emptyState(
            message: 'No hikes planned',
            icon: 'map-trifold',
            action: Act.navigate('add_hike', label: 'Plan a hike'),
          ),
          itemLayout: Display.entryCard(
            title: '{{name}}',
            subtitle: '{{location}}',
            trailing: '{{difficulty}}',
            onTap: Act.navigate(
              'view_hike',
              forwardFields: [
                'name', 'location', 'date', 'difficulty',
                'distance_km', 'status', 'rating', 'notes', 'completed_at',
              ],
              params: {},
            ),
            swipeActions: {
              'right': Act.confirm(
                title: 'Delete Hike',
                message: 'Remove this hike from your plans?',
                onConfirm: Act.deleteEntry(),
              ),
            },
          ),
        ),
      ],
      fab: Actions.fab(
        icon: 'add',
        action: Act.navigate('add_hike', params: {}),
      ),
    ),

    // ═══════════════════════════════════════════
    //  COMPLETED — Done hikes with ratings
    // ═══════════════════════════════════════════
    'completed': Layout.screen(
      appBar: Layout.appBar(title: 'Completed', showBack: false),
      queries: {
        'completed_hikes': Query.def(
          'SELECT id, name, location, date, difficulty, distance_km, '
          'status, rating, notes, completed_at '
          'FROM "m_hikes" '
          'WHERE status = \'Completed\' '
          'ORDER BY completed_at DESC',
        ),
      },
      mutations: {
        'delete': Mut.sql('DELETE FROM "m_hikes" WHERE id = :id'),
      },
      children: [
        Display.entryList(
          source: 'completed_hikes',
          emptyState: Display.emptyState(
            message: 'No completed hikes yet',
            icon: 'check-circle',
          ),
          itemLayout: Display.entryCard(
            title: '{{name}}',
            subtitle: '{{location}}',
            trailing: '{{rating}}',
            onTap: Act.navigate(
              'view_hike',
              forwardFields: [
                'name', 'location', 'date', 'difficulty',
                'distance_km', 'status', 'rating', 'notes', 'completed_at',
              ],
              params: {},
            ),
            swipeActions: {
              'right': Act.confirm(
                title: 'Delete Hike',
                message: 'Delete this completed hike?',
                onConfirm: Act.deleteEntry(),
              ),
            },
          ),
        ),
      ],
    ),

    // ═══════════════════════════════════════════
    //  VIEW HIKE — Detail view
    // ═══════════════════════════════════════════
    'view_hike': Layout.screen(
      appBar: Layout.appBar(title: '{{name}}'),
      mutations: {
        'delete': Mut.sql('DELETE FROM "m_hikes" WHERE id = :id'),
      },
      children: [
        Layout.scrollColumn(children: [
          // Show rating only for completed hikes
          Layout.conditional(
            condition: {'field': 'status', 'op': '==', 'value': 'Completed'},
            thenChildren: [
              Layout.row(children: [
                Display.statCard(
                  label: 'Rating',
                  value: '{{rating}}',
                  accent: true,
                ),
                Display.statCard(
                  label: 'Difficulty',
                  value: '{{difficulty}}',
                ),
              ]),
            ],
          ),
          Layout.section(
            title: 'Details',
            children: [
              Display.textDisplay(label: 'Location', value: '{{location}}'),
              Display.textDisplay(label: 'Date', value: '{{date}}'),
              Display.textDisplay(label: 'Difficulty', value: '{{difficulty}}'),
              Display.textDisplay(label: 'Distance', value: '{{distance_km}}'),
              Display.textDisplay(label: 'Status', value: '{{status}}'),
              Display.textDisplay(label: 'Notes', value: '{{notes}}'),
            ],
          ),
        ]),
      ],
      appBarActions: [
        // Complete button — only shown for planned hikes
        Actions.iconButton(
          icon: 'check-circle',
          tooltip: 'Mark Complete',
          action: Act.navigate(
            'complete_hike',
            forwardFields: ['name', 'location', 'date', 'difficulty', 'distance_km', 'notes'],
            params: {},
          ),
        ),
        Actions.iconButton(
          icon: 'pencil',
          action: Act.navigate(
            'edit_hike',
            forwardFields: [
              'name', 'location', 'date', 'difficulty',
              'distance_km', 'status', 'rating', 'notes',
            ],
            params: {},
          ),
        ),
        Actions.iconButton(
          icon: 'trash',
          action: Act.confirm(
            title: 'Delete Hike',
            message: 'Delete this hike permanently?',
            onConfirm: Act.deleteEntry(),
          ),
        ),
      ],
    ),

    // ═══════════════════════════════════════════
    //  ADD HIKE — Plan a new hike
    // ═══════════════════════════════════════════
    'add_hike': Layout.formScreen(
      title: 'Plan a Hike',
      submitLabel: 'Save Hike',
      defaults: {'status': 'Planned', 'difficulty': 'Moderate'},
      mutations: {
        'create': Mut.object(
          sql: 'INSERT INTO "m_hikes" '
              '(id, name, location, date, difficulty, distance_km, status, notes, created_at, updated_at) '
              'VALUES (:id, :name, :location, :date, :difficulty, :distance_km, :status, :notes, :created_at, :updated_at)',
          reminders: [
            Reminders.onFormSubmit(
              titleField: 'Hike: {{name}}',
              messageField: 'Time to hit the trail at {{location}}!',
              dateField: 'reminder_date',
              timeField: 'reminder_time',
              conditionField: 'set_reminder',
            ),
          ],
        ),
      },
      children: [
        Inputs.textInput(
          fieldKey: 'name', label: 'Hike Name', required: true,
          validation: {'required': true, 'minLength': 1, 'message': 'Give your hike a name'},
        ),
        Inputs.textInput(fieldKey: 'location', label: 'Location / Trail'),
        Inputs.datePicker(fieldKey: 'date', label: 'Planned Date'),
        Inputs.enumSelector(
          fieldKey: 'difficulty', label: 'Difficulty',
          options: ['Easy', 'Moderate', 'Hard', 'Expert'],
        ),
        Inputs.numberInput(fieldKey: 'distance_km', label: 'Distance (km)', min: 0),
        Inputs.textInput(fieldKey: 'notes', label: 'Notes', multiline: true),
        Inputs.toggle(fieldKey: 'set_reminder', label: 'Set Reminder'),
        Inputs.datePicker(
          fieldKey: 'reminder_date',
          label: 'Reminder Date',
          visibleWhen: {'field': 'set_reminder', 'op': '==', 'value': true},
        ),
        Inputs.timePicker(
          fieldKey: 'reminder_time',
          label: 'Reminder Time',
          visibleWhen: {'field': 'set_reminder', 'op': '==', 'value': true},
        ),
      ],
    ),

    // ═══════════════════════════════════════════
    //  EDIT HIKE
    // ═══════════════════════════════════════════
    'edit_hike': Layout.formScreen(
      title: 'Edit Hike',
      editLabel: 'Update',
      mutations: {
        'update': Mut.sql(
          'UPDATE "m_hikes" SET '
          'name = COALESCE(:name, name), '
          'location = COALESCE(:location, location), '
          'date = COALESCE(:date, date), '
          'difficulty = COALESCE(:difficulty, difficulty), '
          'distance_km = COALESCE(:distance_km, distance_km), '
          'status = COALESCE(:status, status), '
          'rating = COALESCE(:rating, rating), '
          'notes = COALESCE(:notes, notes), '
          'updated_at = :updated_at '
          'WHERE id = :id',
        ),
      },
      children: [
        Inputs.textInput(
          fieldKey: 'name', label: 'Hike Name', required: true,
          validation: {'required': true, 'minLength': 1, 'message': 'Give your hike a name'},
        ),
        Inputs.textInput(fieldKey: 'location', label: 'Location / Trail'),
        Inputs.datePicker(fieldKey: 'date', label: 'Planned Date'),
        Inputs.enumSelector(
          fieldKey: 'difficulty', label: 'Difficulty',
          options: ['Easy', 'Moderate', 'Hard', 'Expert'],
        ),
        Inputs.numberInput(fieldKey: 'distance_km', label: 'Distance (km)', min: 0),
        Inputs.enumSelector(
          fieldKey: 'status', label: 'Status',
          options: ['Planned', 'Completed'],
        ),
        Inputs.ratingInput(fieldKey: 'rating', label: 'Rating', maxRating: 5),
        Inputs.textInput(fieldKey: 'notes', label: 'Notes', multiline: true),
      ],
    ),

    // ═══════════════════════════════════════════
    //  COMPLETE HIKE — Mark done + rate
    // ═══════════════════════════════════════════
    'complete_hike': Layout.formScreen(
      title: 'Complete Hike',
      submitLabel: 'Mark Complete',
      defaults: {'status': 'Completed'},
      mutations: {
        'update': Mut.sql(
          'UPDATE "m_hikes" SET '
          'status = \'Completed\', '
          'rating = :rating, '
          'notes = COALESCE(:notes, notes), '
          'completed_at = :updated_at, '
          'updated_at = :updated_at '
          'WHERE id = :id',
        ),
      },
      children: [
        Display.textDisplay(label: 'Hike', value: '{{name}}'),
        Display.textDisplay(label: 'Location', value: '{{location}}'),
        Inputs.ratingInput(
          fieldKey: 'rating', label: 'How was it?', maxRating: 5,
        ),
        Inputs.textInput(
          fieldKey: 'notes', label: 'Notes', multiline: true,
        ),
      ],
    ),
  },
);
