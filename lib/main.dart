// main.dart — Updated with LocalizationService and Welcome Screen
import 'package:app_links/app_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:glucora_ai_companion/core/theme/theme_provider.dart';
import 'package:glucora_ai_companion/core/theme/app_theme.dart';
import 'package:glucora_ai_companion/services/notifications_service.dart';
import 'package:glucora_ai_companion/services/localization_service.dart';
import 'package:glucora_ai_companion/services/location_service.dart';
import 'package:glucora_ai_companion/utils/app_strings.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'features/auth/signup_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/role_selection_screen.dart';
import 'features/patient/screens/patient_navigation.dart';
import 'features/doctor/screens/doctor_main_screen.dart';
import 'features/admin/screens/admin_main_screen.dart';
import 'features/guardian/screens/guardian_main_screen.dart';
import 'features/onboarding/screens/ai_explain_screen.dart';
import 'features/onboarding/screens/landing_screen.dart';
import 'features/onboarding/screens/who_are_we_screen.dart';
import 'features/onboarding/screens/welcome_screen.dart'; 
import 'package:glucora_ai_companion/features/onboarding/screens/onboarding_language_screen.dart' ;
 // Updated import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
    );
  
  await Supabase.initialize(
    url: "https://yzmkzfqgigsaqhnbsiyn.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl6bWt6ZnFnaWdzYXFobmJzaXluIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM3NTY4NzAsImV4cCI6MjA4OTMzMjg3MH0.Z0xEWSa3qbd0KDHgFQfCFJ8Y7EoYfeiNxKRm0mQCsRE",
    authOptions: FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
  );

  await NotificationService.initialize();

  final appLinks = AppLinks();
  appLinks.uriLinkStream.listen((uri) {
    Supabase.instance.client.auth.getSessionFromUrl(uri);
  });

  await Permission.notification.request();
  if (!kIsWeb) {
    await LocationService.initializeService();
  }

  // Initialize localization (loads saved language preference)
  final localizationService = LocalizationService();
  await localizationService.init();
  
  if (localizationService.currentLanguageCode != 'en') {
    await localizationService.translateBatch(AppStrings.getAllStrings());
  }
  
  runApp(GlucoraApp(localizationService: localizationService));
}

class GlucoraApp extends StatelessWidget {
  final LocalizationService localizationService;

  const GlucoraApp({super.key, required this.localizationService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocalizationService>.value(value: localizationService),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
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
  '/welcome': (context) => const WelcomeScreen(), 
  '/onboarding-language': (context) => const OnboardingLanguageScreen(),
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

class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _checkAndStartLocation());
  }

  Future<void> _checkAndStartLocation() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    await NotificationService.saveTokenToSupabase();
    final userMetaRole = user.userMetadata?['role']?.toString();
    final appMetaRole = user.appMetadata['role']?.toString();
    final normalizedRole = (userMetaRole ?? appMetaRole ?? '').trim().toLowerCase();
    if (normalizedRole == 'patient') {
      LocationService.startSharingLocation(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    
    // ✅ If user is logged in, go to their role screen
    if (user != null) {
      final userMetaRole = user.userMetadata?['role']?.toString();
      final appMetaRole = user.appMetadata['role']?.toString();
      final normalizedRole = (userMetaRole ?? appMetaRole ?? '').trim().toLowerCase();
      if (normalizedRole == 'patient') return const PatientNavigation();
      if (normalizedRole == 'doctor') return const DoctorMainScreen();
      if (normalizedRole == 'guardian') return const GuardianMainScreen();
      if (normalizedRole == 'admin') return const AdminMainScreen();
      return const RoleSelectionScreen();
    }
    
    return const WelcomeScreen();
  }
}