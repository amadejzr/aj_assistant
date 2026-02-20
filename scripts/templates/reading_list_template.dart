import '../../lib/features/blueprint/models/blueprint.dart';
import '../../lib/features/blueprint/models/blueprint_action.dart';
import '../../lib/features/blueprint/models/blueprint_template.dart';
import '../../lib/features/blueprint/navigation/module_navigation.dart';

// ─── Shared constants ───

const _allBookFields = [
  'title',
  'author',
  'genre',
  'status',
  'rating',
  'pageCount',
  'dateStarted',
  'dateFinished',
  'notes',
];

const _editBookTap = NavigateAction(
  screen: 'edit_book',
  forwardFields: _allBookFields,
);

// ─── Template ───

final readingListTemplate = BpTemplate(
  name: 'Reading List',
  description: 'Track books, rate reads & build your library',
  longDescription:
      'A personal library tracker to capture what you want to read, follow '
      'your progress through current books, and remember your thoughts on '
      'finished ones. Rate books, browse by genre, and see your reading stats.',
  icon: 'book',
  color: '#5D4037',
  category: 'Lifestyle',
  tags: const ['books', 'reading', 'library', 'literature', 'reviews'],
  sortOrder: 5,
  settings: const {'yearlyGoal': 12},

  guide: const [
    BpGuideStep(
      title: 'Build Your Library',
      body:
          'Add books with the + button. Set status to "Want to Read" for '
          'your wishlist, or "Reading" when you start a new book.',
    ),
    BpGuideStep(
      title: 'Track Progress',
      body:
          'The Reading tab shows everything you\'re currently working '
          'through. When you finish, switch the status to "Finished" '
          'and leave a rating.',
    ),
    BpGuideStep(
      title: 'Yearly Goal',
      body:
          'Set a yearly reading goal from the settings. The Library tab '
          'shows how many books you\'ve finished this year and your '
          'progress toward the target.',
    ),
  ],

  // ─── Navigation ───
  navigation: const ModuleNavigation(
    bottomNav: BottomNav(
      items: [
        NavItem(label: 'Library', icon: 'book', screenId: 'main'),
        NavItem(label: 'Reading', icon: 'bookmark', screenId: 'reading'),
        NavItem(label: 'Finished', icon: 'check_circle', screenId: 'finished'),
      ],
    ),
    drawer: DrawerNav(
      header: 'Reading List',
      items: [
        NavItem(label: 'Add Book', icon: 'add', screenId: 'add_book'),
        NavItem(label: 'Wishlist', icon: 'star', screenId: 'wishlist'),
      ],
    ),
  ),

  // ─── Schema ───
  schemas: const {
    'default': BpSchema(
      label: 'Book',
      icon: 'book',
      fields: [
        BpField.text('title', label: 'Title', required: true),
        BpField.text('author', label: 'Author', required: true),
        BpField.enum_(
          'genre',
          label: 'Genre',
          options: [
            'Fiction',
            'Non-Fiction',
            'Sci-Fi',
            'Fantasy',
            'Mystery',
            'Biography',
            'Self-Help',
            'History',
            'Science',
            'Philosophy',
            'Other',
          ],
        ),
        BpField.enum_(
          'status',
          label: 'Status',
          required: true,
          options: ['Want to Read', 'Reading', 'Finished', 'Abandoned'],
        ),
        BpField.rating('rating', label: 'Rating'),
        BpField.number('pageCount', label: 'Pages'),
        BpField.datetime('dateStarted', label: 'Date Started'),
        BpField.datetime('dateFinished', label: 'Date Finished'),
        BpField.text('notes', label: 'Notes'),
      ],
    ),
  },

  // ─── Screens ───
  screens: {
    // ═══════════════════════════════════════════
    //  LIBRARY — Overview with stats and all books
    // ═══════════════════════════════════════════
    'main': BpScreen(
      title: 'Library',
      appBar: const BpAppBar(
        title: 'Library',
        showBack: false,
        actions: [
          BpIconButton(
            icon: 'settings',
            action: NavigateAction(screen: '_settings'),
          ),
        ],
      ),
      children: [
        BpScrollColumn(
          children: [
            const BpRow(
              children: [
                BpStatCard(label: 'Total Books', expression: 'count()'),
                BpStatCard(
                  label: 'Finished This Year',
                  expression:
                      'count(where(status, ==, Finished), period(year))',
                ),
              ],
            ),
            const BpProgressBar(
              label: 'Yearly Goal',
              expression:
                  'percentage(count(where(status, ==, Finished), period(year)), value(yearlyGoal))',
              format: 'percentage',
            ),
            BpSection(
              title: 'By Genre',
              children: const [
                BpChart(
                  expression: 'group(genre, count())',
                  filter: [BpFilter(field: 'status', value: 'Finished')],
                ),
              ],
            ),
            BpSection(
              title: 'Recently Added',
              children: [
                BpEntryList(
                  query: const BpQuery(orderBy: 'createdAt', limit: 5),
                  itemLayout: const BpEntryCard(
                    title: '{{title}}',
                    subtitle: '{{author}}',
                    trailing: '{{status}}',
                    onTap: _editBookTap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
      fab: const BpFab(
        icon: 'add',
        action: NavigateAction(screen: 'add_book'),
      ),
    ),

    // ═══════════════════════════════════════════
    //  READING — Currently reading
    // ═══════════════════════════════════════════
    'reading': BpScreen(
      appBar: const BpAppBar(title: 'Currently Reading', showBack: false),
      children: [
        BpScrollColumn(
          children: [
            const BpStatCard(
              label: 'In Progress',
              expression: 'count(where(status, ==, Reading))',
            ),
            BpConditional(
              condition: const {
                'expression': 'count(where(status, ==, Reading))',
                'op': '>',
                'value': 0,
              },
              thenChildren: [
                BpEntryList(
                  filter: const [BpFilter(field: 'status', value: 'Reading')],
                  query: const BpQuery(orderBy: 'dateStarted'),
                  itemLayout: const BpEntryCard(
                    title: '{{title}}',
                    subtitle: '{{author}} · {{genre}}',
                    trailing: '{{dateStarted}}',
                    onTap: _editBookTap,
                    swipeActions: BpSwipeActions(
                      left: UpdateEntryAction(
                        data: {'status': 'Finished'},
                        label: 'Finished',
                      ),
                      right: DeleteEntryAction(
                        confirm: true,
                        confirmMessage: 'Remove this book?',
                      ),
                    ),
                  ),
                ),
              ],
              elseChildren: const [
                BpEmptyState(
                  icon: 'book',
                  title: 'Nothing in progress',
                  subtitle:
                      'Add a book and set its status to "Reading" to see it here',
                ),
              ],
            ),
          ],
        ),
      ],
      fab: const BpFab(
        icon: 'add',
        action: NavigateAction(
          screen: 'add_book',
          params: {'_defaultStatus': 'Reading'},
        ),
      ),
    ),

    // ═══════════════════════════════════════════
    //  FINISHED — Completed books with ratings
    // ═══════════════════════════════════════════
    'finished': BpScreen(
      appBar: const BpAppBar(title: 'Finished', showBack: false),
      children: [
        BpScrollColumn(
          children: [
            const BpRow(
              children: [
                BpStatCard(
                  label: 'Books Read',
                  expression: 'count(where(status, ==, Finished))',
                ),
                BpStatCard(
                  label: 'Avg Rating',
                  expression: 'avg(rating, where(status, ==, Finished))',
                  format: 'decimal',
                ),
              ],
            ),
            const BpRow(
              children: [
                BpStatCard(
                  label: 'Pages Read',
                  expression: 'sum(pageCount, where(status, ==, Finished))',
                ),
                BpStatCard(
                  label: 'This Year',
                  expression:
                      'count(where(status, ==, Finished), period(year))',
                ),
              ],
            ),
            BpConditional(
              condition: const {
                'expression': 'count(where(status, ==, Finished))',
                'op': '>',
                'value': 0,
              },
              thenChildren: [
                BpEntryList(
                  filter: const [BpFilter(field: 'status', value: 'Finished')],
                  query: const BpQuery(orderBy: 'dateFinished'),
                  itemLayout: const BpEntryCard(
                    title: '{{title}}',
                    subtitle: '{{author}} · {{genre}}',
                    trailing: '{{rating}}',
                    trailingFormat: 'rating',
                    onTap: _editBookTap,
                    swipeActions: BpSwipeActions(
                      right: DeleteEntryAction(
                        confirm: true,
                        confirmMessage: 'Remove this book?',
                      ),
                    ),
                  ),
                ),
              ],
              elseChildren: const [
                BpEmptyState(
                  icon: 'check_circle',
                  title: 'No finished books yet',
                  subtitle: 'Complete a book and it will show up here',
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    // ═══════════════════════════════════════════
    //  WISHLIST — Want to Read
    // ═══════════════════════════════════════════
    'wishlist': BpScreen(
      title: 'Wishlist',
      children: [
        BpScrollColumn(
          children: [
            const BpStatCard(
              label: 'On the List',
              expression: 'count(where(status, ==, Want to Read))',
            ),
            BpConditional(
              condition: const {
                'expression': 'count(where(status, ==, Want to Read))',
                'op': '>',
                'value': 0,
              },
              thenChildren: [
                BpEntryList(
                  filter: const [
                    BpFilter(field: 'status', value: 'Want to Read'),
                  ],
                  query: const BpQuery(orderBy: 'createdAt'),
                  itemLayout: const BpEntryCard(
                    title: '{{title}}',
                    subtitle: '{{author}} · {{genre}}',
                    onTap: _editBookTap,
                    swipeActions: BpSwipeActions(
                      left: UpdateEntryAction(
                        data: {'status': 'Reading'},
                        label: 'Start Reading',
                      ),
                      right: DeleteEntryAction(
                        confirm: true,
                        confirmMessage: 'Remove from wishlist?',
                      ),
                    ),
                  ),
                ),
              ],
              elseChildren: const [
                BpEmptyState(
                  icon: 'star',
                  title: 'Wishlist is empty',
                  subtitle: 'Add books you want to read',
                ),
              ],
            ),
          ],
        ),
      ],
      fab: const BpFab(
        icon: 'add',
        action: NavigateAction(
          screen: 'add_book',
          params: {'_defaultStatus': 'Want to Read'},
        ),
      ),
    ),

    // ═══════════════════════════════════════════
    //  FORMS
    // ═══════════════════════════════════════════
    'add_book': const BpFormScreen(
      title: 'Add Book',
      defaults: {'status': 'Want to Read'},
      children: [
        BpTextInput(fieldKey: 'title'),
        BpTextInput(fieldKey: 'author'),
        BpEnumSelector(fieldKey: 'genre'),
        BpEnumSelector(fieldKey: 'status'),
        BpNumberInput(fieldKey: 'pageCount'),
        BpConditional(
          condition: {'field': 'status', 'op': '==', 'value': 'Reading'},
          thenChildren: [BpDatePicker(fieldKey: 'dateStarted')],
        ),
        BpConditional(
          condition: {'field': 'status', 'op': '==', 'value': 'Finished'},
          thenChildren: [
            BpSection(
              title: 'Finished Reading',
              children: [
                BpDatePicker(fieldKey: 'dateStarted'),
                BpDatePicker(fieldKey: 'dateFinished'),
                BpRatingInput(fieldKey: 'rating'),
                BpTextInput(fieldKey: 'notes', multiline: true),
              ],
            ),
          ],
        ),
      ],
    ),

    'edit_book': const BpFormScreen(
      title: 'Edit Book',
      editLabel: 'Update',
      children: [
        BpTextInput(fieldKey: 'title'),
        BpTextInput(fieldKey: 'author'),
        BpEnumSelector(fieldKey: 'genre'),
        BpEnumSelector(fieldKey: 'status'),
        BpNumberInput(fieldKey: 'pageCount'),
        BpConditional(
          condition: {'field': 'status', 'op': '==', 'value': 'Reading'},
          thenChildren: [BpDatePicker(fieldKey: 'dateStarted')],
        ),
        BpConditional(
          condition: {'field': 'status', 'op': '==', 'value': 'Finished'},
          thenChildren: [
            BpSection(
              title: 'Finished Reading',
              children: [
                BpDatePicker(fieldKey: 'dateStarted'),
                BpDatePicker(fieldKey: 'dateFinished'),
                BpRatingInput(fieldKey: 'rating'),
                BpTextInput(fieldKey: 'notes', multiline: true),
              ],
            ),
          ],
        ),
      ],
    ),

    'edit_settings': const BpFormScreen(
      title: 'Reading Settings',
      children: [BpNumberInput(fieldKey: 'yearlyGoal')],
    ),
  },
).toJson();
