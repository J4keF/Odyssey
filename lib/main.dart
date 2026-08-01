import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/login_page.dart';
import 'screens/dashboard_page.dart';
import 'services/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GoogleSignIn.instance.initialize();
  runApp(const GoalTrackerApp());
}

class GoalTrackerApp extends StatelessWidget {
  const GoalTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeController(),
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp(
            title: 'Odyssey',
            debugShowCheckedModeBanner: false,
            // CupertinoPageRoute-style swipe-back works out of the box
            // because we use MaterialPageRoute with a MaterialApp.
            // On iOS, edge-swipe back is enabled automatically.
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: themeController.accentColor,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  // Cupertino-style slide on all platforms for swipe back
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                },
              ),
            ),
            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    backgroundColor: Color(0xFFFAF7F4),
                    body: Center(
                      child: CircularProgressIndicator(color: Color(0xFFE8581A)),
                    ),
                  );
                }
                if (snapshot.hasData && snapshot.data != null) {
                  return const DashboardPage();
                }
                return const LoginPage();
              },
            ),
          );
        },
      ),
    );
  }
}