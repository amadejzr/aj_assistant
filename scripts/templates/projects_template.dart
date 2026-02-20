import '../../lib/features/blueprint/models/blueprint.dart';
import '../../lib/features/blueprint/models/blueprint_action.dart';
import '../../lib/features/blueprint/models/blueprint_template.dart';
import '../../lib/features/blueprint/navigation/module_navigation.dart';

// ─── Shared constants ───

const _allProjectFields = [
  'name', 'status', 'priority', 'deadline', 'description',
];

const _allTaskFields = [
  'title', 'project', 'status', 'priority', 'dueDate', 'notes',
];

const _editProjectTap = NavigateAction(
  screen: 'edit_project',
  forwardFields: _allProjectFields,
  params: {'_schemaKey': 'project'},
);

const _editTaskTap = NavigateAction(
  screen: 'edit_task',
  forwardFields: _allTaskFields,
  params: {'_schemaKey': 'task'},
);

const _schemaProject = BpFilter(field: 'schemaKey', value: 'project');
const _schemaTask = BpFilter(field: 'schemaKey', value: 'task');

// ─── Template ───

final projectsTemplate = BpTemplate(
  name: 'Projects',
  description: 'Plan projects, track tasks & ship on time',
  longDescription:
      'A lightweight project tracker to organise work into projects '
      'and break them down into tasks. See what\u2019s active, what\u2019s '
      'overdue, and what got done this week \u2014 all in one place.',
  icon: 'folder',
  color: '#1565C0',
  category: 'Productivity',
  tags: const ['projects', 'tasks', 'planning', 'productivity', 'work'],
  sortOrder: 2,

  guide: const [
    BpGuideStep(
      title: 'Create a Project',
      body: 'Tap the + button on the Projects tab to create a new project. '
          'Give it a name, set a priority, and optionally add a deadline.',
    ),
    BpGuideStep(
      title: 'Add Tasks',
      body: 'Break projects into tasks from the Tasks tab. Pick the project '
          'it belongs to and the task will show up under that project\u2019s name.',
    ),
    BpGuideStep(
      title: 'Track Progress',
      body: 'Move tasks through To Do \u2192 In Progress \u2192 Review \u2192 Done. '
          'The dashboard shows how many tasks you\u2019ve knocked out this week.',
    ),
  ],

  // ─── Navigation ───

  navigation: const ModuleNavigation(
    bottomNav: BottomNav(items: [
      NavItem(label: 'Dashboard', icon: 'chart', screenId: 'main'),
      NavItem(label: 'Projects', icon: 'folder', screenId: 'projects'),
      NavItem(label: 'Tasks', icon: 'list', screenId: 'tasks'),
    ]),
    drawer: DrawerNav(
      header: 'Projects',
      items: [
        NavItem(label: 'New Project', icon: 'add', screenId: 'add_project'),
        NavItem(label: 'New Task', icon: 'add', screenId: 'add_task'),
      ],
    ),
  ),

  // ─── Schemas ───

  schemas: const {
    'project': BpSchema(
      label: 'Project',
      icon: 'folder',
      fields: [
        BpField.text('name', label: 'Project Name', required: true),
        BpField.enum_('status', label: 'Status', required: true, options: [
          'Active', 'On Hold', 'Completed', 'Archived',
        ]),
        BpField.enum_('priority', label: 'Priority', options: [
          'High', 'Medium', 'Low',
        ]),
        BpField.datetime('deadline', label: 'Deadline'),
        BpField.text('description', label: 'Description'),
      ],
    ),
    'task': BpSchema(
      label: 'Task',
      icon: 'list',
      fields: [
        BpField.text('title', label: 'Task', required: true),
        BpField.reference('project',
            label: 'Project', schemaKey: 'project', required: true),
        BpField.enum_('status', label: 'Status', required: true, options: [
          'To Do', 'In Progress', 'Review', 'Done',
        ]),
        BpField.enum_('priority', label: 'Priority', options: [
          'High', 'Medium', 'Low',
        ]),
        BpField.datetime('dueDate', label: 'Due Date'),
        BpField.text('notes', label: 'Notes'),
      ],
    ),
  },

  // ─── Screens ───

  screens: {
    // ═══════════════════════════════════════════
    //  DASHBOARD — Overview with stats
    // ═══════════════════════════════════════════
    'main': BpScreen(
      title: 'Dashboard',
      appBar: const BpAppBar(
        title: 'Projects',
        showBack: false,
        actions: [
          BpIconButton(
            icon: 'settings',
            action: NavigateAction(screen: '_settings'),
          ),
        ],
      ),
      children: [
        BpScrollColumn(children: [
          const BpRow(children: [
            BpStatCard(
              label: 'Active Projects',
              expression:
                  'count(where(status, ==, Active), where(schemaKey, ==, project))',
            ),
            BpStatCard(
              label: 'Open Tasks',
              expression:
                  'count(where(status, !=, Done), where(schemaKey, ==, task))',
            ),
          ]),
          const BpRow(children: [
            BpStatCard(
              label: 'Done This Week',
              expression:
                  'count(where(status, ==, Done), period(week), where(schemaKey, ==, task))',
            ),
            BpStatCard(
              label: 'High Priority',
              expression:
                  'count(where(priority, ==, High), where(status, !=, Done), where(schemaKey, ==, task))',
            ),
          ]),
          BpSection(title: 'Recent Tasks', children: [
            BpEntryList(
              query: const BpQuery(orderBy: 'createdAt', limit: 8),
              filter: const [
                _schemaTask,
                BpFilter(field: 'status', op: '!=', value: 'Done'),
              ],
              itemLayout: const BpEntryCard(
                title: '{{title}}',
                subtitle: '{{project.name}} \u00b7 {{priority}}',
                trailing: '{{status}}',
                onTap: _editTaskTap,
                swipeActions: BpSwipeActions(
                  left: UpdateEntryAction(
                    data: {'status': 'Done'},
                    label: 'Done',
                  ),
                ),
              ),
            ),
          ]),
        ]),
      ],
      fab: const BpFab(
        icon: 'add',
        action: NavigateAction(
          screen: 'add_task',
          params: {'_schemaKey': 'task'},
        ),
      ),
    ),

    // ═══════════════════════════════════════════
    //  PROJECTS — All projects
    // ═══════════════════════════════════════════
    'projects': BpScreen(
      appBar: const BpAppBar(title: 'Projects', showBack: false),
      children: [
        BpScrollColumn(children: [
          const BpRow(children: [
            BpStatCard(
              label: 'Active',
              expression:
                  'count(where(status, ==, Active), where(schemaKey, ==, project))',
            ),
            BpStatCard(
              label: 'Completed',
              expression:
                  'count(where(status, ==, Completed), where(schemaKey, ==, project))',
            ),
          ]),
          BpConditional(
            condition: const {
              'expression': 'count(where(schemaKey, ==, project))',
              'op': '>',
              'value': 0,
            },
            thenChildren: [
              BpEntryList(
                query: const BpQuery(orderBy: 'createdAt'),
                filter: const [_schemaProject],
                itemLayout: const BpEntryCard(
                  title: '{{name}}',
                  subtitle: '{{priority}} priority',
                  trailing: '{{status}}',
                  onTap: _editProjectTap,
                  swipeActions: BpSwipeActions(
                    left: UpdateEntryAction(
                      data: {'status': 'Completed'},
                      label: 'Complete',
                    ),
                    right: DeleteEntryAction(
                      confirm: true,
                      confirmMessage: 'Delete this project?',
                    ),
                  ),
                ),
              ),
            ],
            elseChildren: const [
              BpEmptyState(
                icon: 'folder',
                title: 'No projects yet',
                subtitle: 'Create your first project to get started',
              ),
            ],
          ),
        ]),
      ],
      fab: const BpFab(
        icon: 'add',
        action: NavigateAction(
          screen: 'add_project',
          params: {'_schemaKey': 'project'},
        ),
      ),
    ),

    // ═══════════════════════════════════════════
    //  TASKS — All tasks across projects
    // ═══════════════════════════════════════════
    'tasks': BpScreen(
      appBar: const BpAppBar(title: 'Tasks', showBack: false),
      children: [
        BpScrollColumn(children: [
          const BpRow(children: [
            BpStatCard(
              label: 'To Do',
              expression:
                  'count(where(status, ==, To Do), where(schemaKey, ==, task))',
            ),
            BpStatCard(
              label: 'In Progress',
              expression:
                  'count(where(status, ==, In Progress), where(schemaKey, ==, task))',
            ),
          ]),
          BpConditional(
            condition: const {
              'expression': 'count(where(schemaKey, ==, task))',
              'op': '>',
              'value': 0,
            },
            thenChildren: [
              BpEntryList(
                query: const BpQuery(orderBy: 'dueDate'),
                filter: const [
                  _schemaTask,
                  BpFilter(field: 'status', op: '!=', value: 'Done'),
                ],
                itemLayout: const BpEntryCard(
                  title: '{{title}}',
                  subtitle: '{{project.name}} \u00b7 {{priority}}',
                  trailing: '{{dueDate}}',
                  onTap: _editTaskTap,
                  swipeActions: BpSwipeActions(
                    left: UpdateEntryAction(
                      data: {'status': 'Done'},
                      label: 'Done',
                    ),
                    right: DeleteEntryAction(
                      confirm: true,
                      confirmMessage: 'Delete this task?',
                    ),
                  ),
                ),
              ),
            ],
            elseChildren: const [
              BpEmptyState(
                icon: 'list',
                title: 'No tasks yet',
                subtitle: 'Add a task to start tracking your work',
              ),
            ],
          ),
        ]),
      ],
      fab: const BpFab(
        icon: 'add',
        action: NavigateAction(
          screen: 'add_task',
          params: {'_schemaKey': 'task'},
        ),
      ),
    ),

    // ═══════════════════════════════════════════
    //  FORMS
    // ═══════════════════════════════════════════
    'add_project': const BpFormScreen(
      title: 'New Project',
      defaults: {'status': 'Active', 'priority': 'Medium'},
      children: [
        BpTextInput(fieldKey: 'name'),
        BpEnumSelector(fieldKey: 'status'),
        BpEnumSelector(fieldKey: 'priority'),
        BpDatePicker(fieldKey: 'deadline'),
        BpTextInput(fieldKey: 'description', multiline: true),
      ],
    ),

    'edit_project': const BpFormScreen(
      title: 'Edit Project',
      editLabel: 'Update',
      children: [
        BpTextInput(fieldKey: 'name'),
        BpEnumSelector(fieldKey: 'status'),
        BpEnumSelector(fieldKey: 'priority'),
        BpDatePicker(fieldKey: 'deadline'),
        BpTextInput(fieldKey: 'description', multiline: true),
      ],
    ),

    'add_task': const BpFormScreen(
      title: 'New Task',
      defaults: {'status': 'To Do', 'priority': 'Medium'},
      children: [
        BpTextInput(fieldKey: 'title'),
        BpReferencePicker(
          fieldKey: 'project',
          schemaKey: 'project',
          displayField: 'name',
        ),
        BpEnumSelector(fieldKey: 'status'),
        BpEnumSelector(fieldKey: 'priority'),
        BpDatePicker(fieldKey: 'dueDate'),
        BpTextInput(fieldKey: 'notes', multiline: true),
      ],
    ),

    'edit_task': const BpFormScreen(
      title: 'Edit Task',
      editLabel: 'Update',
      children: [
        BpTextInput(fieldKey: 'title'),
        BpReferencePicker(
          fieldKey: 'project',
          schemaKey: 'project',
          displayField: 'name',
        ),
        BpEnumSelector(fieldKey: 'status'),
        BpEnumSelector(fieldKey: 'priority'),
        BpDatePicker(fieldKey: 'dueDate'),
        BpTextInput(fieldKey: 'notes', multiline: true),
      ],
    ),
  },
).toJson();
