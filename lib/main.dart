import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';

import 'screens/login_page.dart';
import 'screens/dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const GoalTrackerApp());
}

class GoalTrackerApp extends StatelessWidget {
  const GoalTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Goal Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE8581A),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      // StreamBuilder listens to Firebase auth state
      // Firebase emits a User on user log in, on user log out it emits null.
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
  }
}