// main.dart
import 'package:app_links/app_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glucora_ai_companion/core/theme/theme_provider.dart';
import 'package:glucora_ai_companion/core/theme/app_theme.dart';
import 'features/auth/signup_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/role_selection_screen.dart';
import 'features/user/patient_navigation.dart';
import 'features/doctor/screens/doctor_main_screen.dart';
import 'features/admin/screens/admin_main_screen.dart';
import 'features/guardian/screens/guardian_main_screen.dart';
import 'features/onboarding/screens/ai_explain_screen.dart';
import 'features/onboarding/screens/landing_screen.dart';
import 'features/onboarding/screens/who_are_we_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:glucora_ai_companion/services/location_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: "https://yzmkzfqgigsaqhnbsiyn.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl6bWt6ZnFnaWdzYXFobmJzaXluIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM3NTY4NzAsImV4cCI6MjA4OTMzMjg3MH0.Z0xEWSa3qbd0KDHgFQfCFJ8Y7EoYfeiNxKRm0mQCsRE",
    authOptions: FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
  );

  final appLinks = AppLinks();

  appLinks.uriLinkStream.listen((uri) {
    Supabase.instance.client.auth.getSessionFromUrl(uri);
  });

  await Permission.notification.request();
  if (!kIsWeb) {
  await LocationService.initializeService();
}

  runApp(const GlucoraApp());
}

class GlucoraApp extends StatelessWidget {
  const GlucoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Glucora',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeProvider.themeMode,
            home: const _StartupGate(),
            routes: {
              '/who-we-are': (context) => const WhoWeAreScreen(),
              '/ai-explain': (context) => const AIExplainScreen(),
              '/landing': (context) => const LandingScreen(),
              '/login-screen': (context) => const LoginScreen(),
              '/sign-up': (context) => const SignUpScreen(),
              '/role-selection': (context) => const RoleSelectionScreen(),
            },
          );
        },
      ),
    );
  }
}
/* 
class _StartupGate extends StatelessWidget {
  const _StartupGate();

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return const WhoWeAreScreen();
    }

    final userMetaRole = user.userMetadata?['role']?.toString();
    final appMetaRole = user.appMetadata['role']?.toString();
    final normalizedRole = (userMetaRole ?? appMetaRole ?? '')
        .trim()
        .toLowerCase();

    if (normalizedRole == 'patient') {
      return const PatientNavigation();
    }
    if (normalizedRole == 'doctor') {
      return const DoctorMainScreen();
    }
    if (normalizedRole == 'guardian') {
      return const GuardianMainScreen();
    }
    if (normalizedRole == 'admin') {
      return const AdminMainScreen();
    }

    return const RoleSelectionScreen();
  }
}
 */

class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _checkAndStartLocation();
    });
  }

  Future<void> _checkAndStartLocation() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final userMetaRole = user.userMetadata?['role']?.toString();
    final appMetaRole = user.appMetadata['role']?.toString();
    final normalizedRole = (userMetaRole ?? appMetaRole ?? '')
        .trim()
        .toLowerCase();

    if (normalizedRole == 'patient') {
      LocationService.startSharingLocation(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return const WhoWeAreScreen();

    final userMetaRole = user.userMetadata?['role']?.toString();
    final appMetaRole = user.appMetadata['role']?.toString();
    final normalizedRole = (userMetaRole ?? appMetaRole ?? '')
        .trim()
        .toLowerCase();

    if (normalizedRole == 'patient') return const PatientNavigation();
    if (normalizedRole == 'doctor') return const DoctorMainScreen();
    if (normalizedRole == 'guardian') return const GuardianMainScreen();
    if (normalizedRole == 'admin') return const AdminMainScreen();

    return const RoleSelectionScreen();
  }
}
