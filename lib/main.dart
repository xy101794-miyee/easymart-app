import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'data/database.dart';
import 'providers/easymart_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/customer/home_screen.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.initialize();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ChangeNotifierProvider(
      create: (_) => EasymartProvider(prefs),
      child: const EasymartApp(),
    ),
  );
}

class EasymartApp extends StatelessWidget {
  const EasymartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Easymart',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home': (_) => const CustomerHomeScreen(),
      },
      home: const SplashScreen(),
    );
  }
}
