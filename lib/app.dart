import 'package:flutter/material.dart';

import 'app_router.dart';
import 'core/theme/app_theme.dart';

class AJAssistantApp extends StatelessWidget {
  const AJAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AJ Assistant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
