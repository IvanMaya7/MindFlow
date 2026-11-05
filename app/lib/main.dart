import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'core/theme.dart';
import 'features/auth/login_screen.dart';
import 'features/home/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.instance.loadToken();
  runApp(const MindFlowApp());
}

class MindFlowApp extends StatelessWidget {
  const MindFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: ApiClient.instance.isLoggedIn ? const MainShell() : const LoginScreen(),
    );
  }
}
