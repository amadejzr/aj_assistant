const readingListTemplate = {
  'name': 'Reading List',
  'description': 'Track books, rate reads & build your library',
  'longDescription':
      'A personal library tracker to capture what you want to read, follow '
      'your progress through current books, and remember your thoughts on '
      'finished ones. Rate books, browse by genre, and see your reading stats.',
  'icon': 'book',
  'color': '#5D4037',
  'category': 'Lifestyle',
  'tags': ['books', 'reading', 'library', 'literature', 'reviews'],
  'featured': false,
  'sortOrder': 5,
  'installCount': 0,
  'version': 1,
  'settings': {
    'yearlyGoal': 12,
  },
  'guide': [
    {
      'title': 'Build Your Library',
      'body':
          'Add books with the + button. Set status to "Want to Read" for your '
          'wishlist, or "Reading" when you start a new book.',
    },
    {
      'title': 'Track Progress',
      'body':
          'The Reading tab shows everything you\'re currently working through. '
          'When you finish, switch the status to "Finished" and leave a rating.',
    },
    {
      'title': 'Yearly Goal',
      'body':
          'Set a yearly reading goal from the settings. The Library tab shows '
          'how many books you\'ve finished this year and your progress toward '
          'the target.',
    },
  ],

  // ─── Navigation ───
  'navigation': {
    'bottomNav': {
      'items': [
        {'label': 'Library', 'icon': 'book', 'screenId': 'main'},
        {'label': 'Reading', 'icon': 'bookmark', 'screenId': 'reading'},
        {'label': 'Finished', 'icon': 'check_circle', 'screenId': 'finished'},
      ],
    },
    'drawer': {
      'header': 'Reading List',
      'items': [
        {'label': 'Add Book', 'icon': 'add', 'screenId': 'add_book'},
        {'label': 'Wishlist', 'icon': 'star', 'screenId': 'wishlist'},
      ],
    },
  },

  // ─── Schemas ───
  'schemas': {
    'default': {
      'label': 'Book',
      'icon': 'book',
      'fields': {
        'title': {
          'key': 'title',
          'type': 'text',
          'label': 'Title',
          'required': true,
        },
        'author': {
          'key': 'author',
          'type': 'text',
          'label': 'Author',
          'required': true,
        },
        'genre': {
          'key': 'genre',
          'type': 'enumType',
          'label': 'Genre',
          'options': [
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
        },
        'status': {
          'key': 'status',
          'type': 'enumType',
          'label': 'Status',
          'required': true,
          'options': ['Want to Read', 'Reading', 'Finished', 'Abandoned'],
        },
        'rating': {
          'key': 'rating',
          'type': 'rating',
          'label': 'Rating',
          'constraints': {'min': 1, 'max': 5},
        },
        'pageCount': {
          'key': 'pageCount',
          'type': 'number',
          'label': 'Pages',
        },
        'dateStarted': {
          'key': 'dateStarted',
          'type': 'datetime',
          'label': 'Date Started',
        },
        'dateFinished': {
          'key': 'dateFinished',
          'type': 'datetime',
          'label': 'Date Finished',
        },
        'notes': {
          'key': 'notes',
          'type': 'text',
          'label': 'Notes',
        },
      },
    },
  },

  // ─── Screens ───
  'screens': {
    // ═══════════════════════════════════════════
    //  LIBRARY — Overview with stats and all books
    // ═══════════════════════════════════════════
    'main': {
      'id': 'main',
      'type': 'screen',
      'title': 'Library',
      'appBar': {
        'type': 'app_bar',
        'title': 'Library',
        'showBack': false,
        'actions': [
          {
            'type': 'icon_button',
            'icon': 'settings',
            'action': {'type': 'navigate', 'screen': '_settings'},
          },
        ],
      },
      'children': [
        {
          'type': 'scroll_column',
          'children': [
            {
              'type': 'row',
              'children': [
                {
                  'type': 'stat_card',
                  'label': 'Total Books',
                  'expression': 'count()',
                },
                {
                  'type': 'stat_card',
                  'label': 'Finished This Year',
                  'expression':
                      'count(where(status, ==, Finished), period(year))',
                },
              ],
            },
            {
              'type': 'progress_bar',
              'label': 'Yearly Goal',
              'expression':
                  'percentage(count(where(status, ==, Finished), period(year)), value(yearlyGoal))',
              'format': 'percentage',
            },
            {
              'type': 'section',
              'title': 'By Genre',
              'children': [
                {
                  'type': 'chart',
                  'chartType': 'donut',
                  'expression': 'group(genre, count())',
                  'filter': [
                    {'field': 'status', 'op': '==', 'value': 'Finished'},
                  ],
                },
              ],
            },
            {
              'type': 'section',
              'title': 'Recently Added',
              'children': [
                {
                  'type': 'entry_list',
                  'query': {
                    'orderBy': 'createdAt',
                    'direction': 'desc',
                    'limit': 5,
                  },
                  'itemLayout': {
                    'type': 'entry_card',
                    'title': '{{title}}',
                    'subtitle': '{{author}}',
                    'trailing': '{{status}}',
                    'onTap': {
                      'type': 'navigate',
                      'screen': 'edit_book',
                      'forwardFields': [
                        'title',
                        'author',
                        'genre',
                        'status',
                        'rating',
                        'pageCount',
                        'dateStarted',
                        'dateFinished',
                        'notes',
                      ],
                    },
                  },
                },
              ],
            },
          ],
        },
      ],
      'fab': {
        'type': 'fab',
        'icon': 'add',
        'action': {'type': 'navigate', 'screen': 'add_book'},
      },
    },

    // ═══════════════════════════════════════════
    //  READING — Currently reading
    // ═══════════════════════════════════════════
    'reading': {
      'id': 'reading',
      'type': 'screen',
      'appBar': {
        'type': 'app_bar',
        'title': 'Currently Reading',
        'showBack': false,
      },
      'children': [
        {
          'type': 'scroll_column',
          'children': [
            {
              'type': 'stat_card',
              'label': 'In Progress',
              'expression': 'count(where(status, ==, Reading))',
            },
            {
              'type': 'conditional',
              'condition': {
                'expression': 'count(where(status, ==, Reading))',
                'op': '>',
                'value': 0,
              },
              'then': [
                {
                  'type': 'entry_list',
                  'filter': [
                    {'field': 'status', 'op': '==', 'value': 'Reading'},
                  ],
                  'query': {'orderBy': 'dateStarted', 'direction': 'desc'},
                  'itemLayout': {
                    'type': 'entry_card',
                    'title': '{{title}}',
                    'subtitle': '{{author}} · {{genre}}',
                    'trailing': '{{dateStarted}}',
                    'onTap': {
                      'type': 'navigate',
                      'screen': 'edit_book',
                      'forwardFields': [
                        'title',
                        'author',
                        'genre',
                        'status',
                        'rating',
                        'pageCount',
                        'dateStarted',
                        'dateFinished',
                        'notes',
                      ],
                    },
                    'swipeActions': {
                      'left': {
                        'type': 'update_entry',
                        'data': {'status': 'Finished'},
                        'label': 'Finished',
                      },
                      'right': {
                        'type': 'delete_entry',
                        'confirm': true,
                        'confirmMessage': 'Remove this book?',
                      },
                    },
                  },
                },
              ],
              'else': [
                {
                  'type': 'empty_state',
                  'icon': 'book',
                  'title': 'Nothing in progress',
                  'subtitle':
                      'Add a book and set its status to "Reading" to see it here',
                },
              ],
            },
          ],
        },
      ],
      'fab': {
        'type': 'fab',
        'icon': 'add',
        'action': {
          'type': 'navigate',
          'screen': 'add_book',
          'params': {'_defaultStatus': 'Reading'},
        },
      },
    },

    // ═══════════════════════════════════════════
    //  FINISHED — Completed books with ratings
    // ═══════════════════════════════════════════
    'finished': {
      'id': 'finished',
      'type': 'screen',
      'appBar': {
        'type': 'app_bar',
        'title': 'Finished',
        'showBack': false,
      },
      'children': [
        {
          'type': 'scroll_column',
          'children': [
            {
              'type': 'row',
              'children': [
                {
                  'type': 'stat_card',
                  'label': 'Books Read',
                  'expression': 'count(where(status, ==, Finished))',
                },
                {
                  'type': 'stat_card',
                  'label': 'Avg Rating',
                  'expression':
                      'avg(rating, where(status, ==, Finished))',
                  'format': 'decimal',
                },
              ],
            },
            {
              'type': 'row',
              'children': [
                {
                  'type': 'stat_card',
                  'label': 'Pages Read',
                  'expression':
                      'sum(pageCount, where(status, ==, Finished))',
                },
                {
                  'type': 'stat_card',
                  'label': 'This Year',
                  'expression':
                      'count(where(status, ==, Finished), period(year))',
                },
              ],
            },
            {
              'type': 'conditional',
              'condition': {
                'expression': 'count(where(status, ==, Finished))',
                'op': '>',
                'value': 0,
              },
              'then': [
                {
                  'type': 'entry_list',
                  'filter': [
                    {'field': 'status', 'op': '==', 'value': 'Finished'},
                  ],
                  'query': {'orderBy': 'dateFinished', 'direction': 'desc'},
                  'itemLayout': {
                    'type': 'entry_card',
                    'title': '{{title}}',
                    'subtitle': '{{author}} · {{genre}}',
                    'trailing': '{{rating}}',
                    'trailingFormat': 'rating',
                    'onTap': {
                      'type': 'navigate',
                      'screen': 'edit_book',
                      'forwardFields': [
                        'title',
                        'author',
                        'genre',
                        'status',
                        'rating',
                        'pageCount',
                        'dateStarted',
                        'dateFinished',
                        'notes',
                      ],
                    },
                    'swipeActions': {
                      'right': {
                        'type': 'delete_entry',
                        'confirm': true,
                        'confirmMessage': 'Remove this book?',
                      },
                    },
                  },
                },
              ],
              'else': [
                {
                  'type': 'empty_state',
                  'icon': 'check_circle',
                  'title': 'No finished books yet',
                  'subtitle': 'Complete a book and it will show up here',
                },
              ],
            },
          ],
        },
      ],
    },

    // ═══════════════════════════════════════════
    //  WISHLIST — Want to Read
    // ═══════════════════════════════════════════
    'wishlist': {
      'id': 'wishlist',
      'type': 'screen',
      'title': 'Wishlist',
      'children': [
        {
          'type': 'scroll_column',
          'children': [
            {
              'type': 'stat_card',
              'label': 'On the List',
              'expression': 'count(where(status, ==, Want to Read))',
            },
            {
              'type': 'conditional',
              'condition': {
                'expression': 'count(where(status, ==, Want to Read))',
                'op': '>',
                'value': 0,
              },
              'then': [
                {
                  'type': 'entry_list',
                  'filter': [
                    {'field': 'status', 'op': '==', 'value': 'Want to Read'},
                  ],
                  'query': {'orderBy': 'createdAt', 'direction': 'desc'},
                  'itemLayout': {
                    'type': 'entry_card',
                    'title': '{{title}}',
                    'subtitle': '{{author}} · {{genre}}',
                    'onTap': {
                      'type': 'navigate',
                      'screen': 'edit_book',
                      'forwardFields': [
                        'title',
                        'author',
                        'genre',
                        'status',
                        'rating',
                        'pageCount',
                        'dateStarted',
                        'dateFinished',
                        'notes',
                      ],
                    },
                    'swipeActions': {
                      'left': {
                        'type': 'update_entry',
                        'data': {'status': 'Reading'},
                        'label': 'Start Reading',
                      },
                      'right': {
                        'type': 'delete_entry',
                        'confirm': true,
                        'confirmMessage': 'Remove from wishlist?',
                      },
                    },
                  },
                },
              ],
              'else': [
                {
                  'type': 'empty_state',
                  'icon': 'star',
                  'title': 'Wishlist is empty',
                  'subtitle': 'Add books you want to read',
                },
              ],
            },
          ],
        },
      ],
      'fab': {
        'type': 'fab',
        'icon': 'add',
        'action': {
          'type': 'navigate',
          'screen': 'add_book',
          'params': {'_defaultStatus': 'Want to Read'},
        },
      },
    },

    // ═══════════════════════════════════════════
    //  FORMS
    // ═══════════════════════════════════════════
    'add_book': {
      'id': 'add_book',
      'type': 'form_screen',
      'title': 'Add Book',
      'submitLabel': 'Save',
      'defaults': {'status': 'Want to Read'},
      'children': [
        {'type': 'text_input', 'fieldKey': 'title'},
        {'type': 'text_input', 'fieldKey': 'author'},
        {'type': 'enum_selector', 'fieldKey': 'genre'},
        {'type': 'enum_selector', 'fieldKey': 'status'},
        {'type': 'number_input', 'fieldKey': 'pageCount'},
        {
          'type': 'conditional',
          'condition': {'field': 'status', 'op': '==', 'value': 'Reading'},
          'then': [
            {'type': 'date_picker', 'fieldKey': 'dateStarted'},
          ],
        },
        {
          'type': 'conditional',
          'condition': {'field': 'status', 'op': '==', 'value': 'Finished'},
          'then': [
            {
              'type': 'section',
              'title': 'Finished Reading',
              'children': [
                {'type': 'date_picker', 'fieldKey': 'dateStarted'},
                {'type': 'date_picker', 'fieldKey': 'dateFinished'},
                {'type': 'rating_input', 'fieldKey': 'rating'},
                {'type': 'text_input', 'fieldKey': 'notes', 'multiline': true},
              ],
            },
          ],
        },
      ],
    },

    'edit_book': {
      'id': 'edit_book',
      'type': 'form_screen',
      'title': 'Edit Book',
      'editLabel': 'Update',
      'children': [
        {'type': 'text_input', 'fieldKey': 'title'},
        {'type': 'text_input', 'fieldKey': 'author'},
        {'type': 'enum_selector', 'fieldKey': 'genre'},
        {'type': 'enum_selector', 'fieldKey': 'status'},
        {'type': 'number_input', 'fieldKey': 'pageCount'},
        {
          'type': 'conditional',
          'condition': {'field': 'status', 'op': '==', 'value': 'Reading'},
          'then': [
            {'type': 'date_picker', 'fieldKey': 'dateStarted'},
          ],
        },
        {
          'type': 'conditional',
          'condition': {'field': 'status', 'op': '==', 'value': 'Finished'},
          'then': [
            {
              'type': 'section',
              'title': 'Finished Reading',
              'children': [
                {'type': 'date_picker', 'fieldKey': 'dateStarted'},
                {'type': 'date_picker', 'fieldKey': 'dateFinished'},
                {'type': 'rating_input', 'fieldKey': 'rating'},
                {'type': 'text_input', 'fieldKey': 'notes', 'multiline': true},
              ],
            },
          ],
        },
      ],
    },

    // ─── Settings ───
    'edit_settings': {
      'id': 'edit_settings',
      'type': 'form_screen',
      'title': 'Reading Settings',
      'submitLabel': 'Save',
      'children': [
        {
          'type': 'number_input',
          'fieldKey': 'yearlyGoal',
          'label': 'Yearly Reading Goal',
        },
      ],
    },
  },
};
