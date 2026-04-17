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
import 'package:glucora_ai_companion/core/utils/app_strings.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:glucora_ai_companion/services/ai_prediction_upload_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/role_selection_screen.dart';
import 'features/patient/widgets/patient_shell.dart' as patientShell;
import 'features/doctor/widgets/doctor_shell.dart';
import 'features/admin/screens/admin_main_screen.dart';
import 'features/guardian/widgets/guardian_shell.dart';
import 'features/onboarding/screens/ai_explain_screen.dart';
import 'features/onboarding/screens/landing_screen.dart';
import 'features/onboarding/screens/who_are_we_screen.dart';
import 'features/onboarding/screens/welcome_screen.dart';
import 'package:glucora_ai_companion/features/onboarding/screens/onboarding_language_screen.dart';
import 'package:glucora_ai_companion/features/auth/screens/reset_password_screen.dart';
import 'package:glucora_ai_companion/services/ai_prediction_upload_service.dart';
import 'package:glucora_ai_companion/services/ble/ble_hardware_service.dart';
import 'package:glucora_ai_companion/services/ble/ble_hardware_data.dart';
import 'package:glucora_ai_companion/services/ble/ble_hardware_repository.dart';

import 'package:glucora_ai_companion/services/supabase_service.dart';
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Supabase.initialize(
    url: "https://yzmkzfqgigsaqhnbsiyn.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl6bWt6ZnFnaWdzYXFobmJzaXluIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM3NTY4NzAsImV4cCI6MjA4OTMzMjg3MH0.Z0xEWSa3qbd0KDHgFQfCFJ8Y7EoYfeiNxKRm0mQCsRE",
    authOptions: FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
  );

  await NotificationService.initialize();

  final appLinks = AppLinks();

  appLinks.uriLinkStream.listen((uri) async {
    final type = uri.queryParameters['type'];
    final tokenHash = uri.queryParameters['token_hash'];

    if (type == 'recovery' && tokenHash != null) {
      await Supabase.instance.client.auth.verifyOTP(
        type: OtpType.recovery,
        tokenHash: tokenHash,
      );
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
        (route) => false,
      );
      return;
    }

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
  // Handle cold start from deep link
  final initialUri = await appLinks.getInitialLink();
  if (initialUri != null) {
    final type = initialUri.queryParameters['type'];
    final tokenHash = initialUri.queryParameters['token_hash'];
    if (type == 'recovery' && tokenHash != null) {
      try {
        await Supabase.instance.client.auth.verifyOTP(
          type: OtpType.recovery,
          tokenHash: tokenHash,
        );
        print('Cold start recovery session established');
      } catch (e) {
        print('Cold start verifyOTP failed: $e');
      }
    }
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
        ChangeNotifierProvider<LocalizationService>.value(
          value: localizationService,
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'Glucora',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeProvider.themeMode,
            home: const _StartupGate(),
            routes: {
              '/welcome': (context) => const WelcomeScreen(),
              '/onboarding-language': (context) =>
                  const OnboardingLanguageScreen(),
              '/who-we-are': (context) => const WhoWeAreScreen(),
              '/ai-explain': (context) => const AIExplainScreen(),
              '/landing': (context) => const LandingScreen(),
              '/login-screen': (context) => const LoginScreen(),
              '/sign-up': (context) => const SignUpScreen(),
              '/role-selection': (context) => const RoleSelectionScreen(),
              '/bluetooth-pairing': (context) => const BluetoothPairingScreen(),
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
    final normalizedRole = (userMetaRole ?? appMetaRole ?? '')
        .trim()
        .toLowerCase();
    if (normalizedRole == 'patient') {
      LocationService.startSharingLocation(user.id);
    AiPredictionUploadService.instance.startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    // ✅ If user is logged in, go to their role screen
    if (user != null) {
      final userMetaRole = user.userMetadata?['role']?.toString();
      final appMetaRole = user.appMetadata['role']?.toString();
      final normalizedRole = (userMetaRole ?? appMetaRole ?? '')
          .trim()
          .toLowerCase();
      if (normalizedRole == 'patient') {
        return const patientShell.PatientNavigation();
      } else if (normalizedRole == 'doctor') {
        return const DoctorMainScreen();
      } else if (normalizedRole == 'guardian') {
        return const GuardianMainScreen();
      } else if (normalizedRole == 'admin') {
        return const AdminMainScreen();
      } else {
        return const RoleSelectionScreen();
      }
    }

    return const WelcomeScreen();
  }
}
