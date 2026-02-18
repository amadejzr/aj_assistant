/// Seeds `marketplace_templates` in Firestore with starter templates.
///
/// Run:
///   cd scripts && make seed
///
/// Requires a service account key at scripts/service-account.json.
/// Get one from: Firebase Console → Project Settings → Service Accounts
library;

import 'dart:io';

import 'package:dart_firebase_admin/dart_firebase_admin.dart';
import 'package:dart_firebase_admin/firestore.dart';

import 'templates/finance_template.dart';
import 'templates/fitness_template.dart';
import 'templates/hiking_template.dart';
import 'templates/meals_template.dart';

Future<void> main() async {
  final admin = FirebaseAdminApp.initializeApp(
    'assistant-16a63',
    Credential.fromServiceAccount(File('service-account.json')),
  );

  final firestore = Firestore(admin);
  final collection = firestore.collection('marketplace_templates');

  final templates = {
    'tpl_finance': financeTemplate,
    'tpl_fitness': fitnessTemplate,
    'tpl_hiking': hikingTemplate,
    'tpl_meals': mealsTemplate,
  };

  for (final entry in templates.entries) {
    print('Writing ${entry.key}...');
    await collection.doc(entry.key).set(entry.value);
  }

  print('Done — ${templates.length} templates seeded.');
  await admin.close();
}
