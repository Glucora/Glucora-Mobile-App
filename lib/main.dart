import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'features/user/patient_navigation.dart';
import 'features/doctor/screens/doctor_main_screen.dart';
import 'features/guardian/screens/guardian_main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

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
      home: const RoleSelectionScreen(),
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
                  MaterialPageRoute(
                    builder: (_) => const PatientNavigation(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text("Doctor Side"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DoctorMainScreen(),
                  ),
                );
              },
            ),            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text("Guardian Side"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GuardianMainScreen(),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}