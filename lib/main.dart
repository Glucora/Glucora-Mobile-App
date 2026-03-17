import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glucora_ai_companion/features/auth/signup_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/user/patient_navigation.dart';
import 'features/doctor/screens/doctor_main_screen.dart';
import 'features/admin/screens/admin_main_screen.dart';
import 'features/guardian/screens/guardian_main_screen.dart';
import 'features/onboarding/screens/ai_explain_screen.dart';
import 'features/onboarding/screens/landing_screen.dart';
import 'features/onboarding/screens/who_are_we_screen.dart';

void main() async {
   WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: "https://yzmkzfqgigsaqhnbsiyn.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl6bWt6ZnFnaWdzYXFobmJzaXluIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM3NTY4NzAsImV4cCI6MjA4OTMzMjg3MH0.Z0xEWSa3qbd0KDHgFQfCFJ8Y7EoYfeiNxKRm0mQCsRE",
  );

  runApp(const GlucoraApp());
}

class GlucoraApp extends StatelessWidget {
  const GlucoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Glucora',
      theme: ThemeData(
        primaryColor: const Color(0xFF2BB6A3),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      initialRoute: '/who-we-are',
      routes: {
        '/who-we-are': (context) => const WhoWeAreScreen(),
        '/ai-explain': (context) => const AIExplainScreen(),
        '/landing': (context) => const LandingScreen(),
        '/login-screen': (context) => const LoginScreen(),
        '/sign-up': (context) => const SignUpScreen(),
        '/role-selection': (context) => const RoleSelectionScreen(),
      },
    );
  }
}

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text("Patient Side"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PatientNavigation()),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text("Doctor Side"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DoctorMainScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text("Admin Side"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminMainScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text("Guardian Side"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DoctorMainScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text("Guardian Side"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GuardianMainScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
