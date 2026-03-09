import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:driver_app/features/auth/presentation/login_screen.dart';
import 'package:driver_app/features/auth/services/auth_service.dart';
import 'package:driver_app/features/home/presentation/home_screen.dart';
import 'package:driver_app/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:driver_app/features/tracking/presentation/live_tracking_viewer_screen.dart';

/// Supabase configuration
/// Replace these with your actual Supabase project credentials
/// Using jiobase URL to work in India
const String supabaseUrl = 'https://driver-fleet.jiobase.com';
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZvcGF0dWV1dmt6eGV1bmp3aHZwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA0NjcwNTcsImV4cCI6MjA4NjA0MzA1N30.vdS5HpNudKU4SRJMtusIt1xlIjic8q0MzgpYZX6MOLc';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const DriverFleetApp());
}

class DriverFleetApp extends StatelessWidget {
  const DriverFleetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Driver Fleet App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: GoogleFonts.poppins().fontFamily,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE53935),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: Colors.black),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: const CardThemeData(elevation: 2),
      ),
      home: const _AuthGate(),
      onGenerateRoute: _onGenerateRoute,
    );
  }

  static Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    // Handle tracking links: /track/:token
    final uri = Uri.parse(settings.name ?? '');
    if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'track') {
      final token = uri.pathSegments[1];
      return MaterialPageRoute(
        builder: (_) => LiveTrackingViewerScreen(trackingToken: token),
      );
    }
    return null;
  }
}

/// Routes to LoginScreen, HomeScreen, or AdminDashboardScreen based on auth + role.
/// Uses Supabase Auth for authentication.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: AuthService.instance.onAuthStateChange,
      builder: (context, snapshot) {
        // While loading, show a branded splash
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFFF5F6FA),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFE53935)),
            ),
          );
        }

        final session = snapshot.data!.session;

        if (session != null) {
          // Check role and route accordingly
          return FutureBuilder<String>(
            future: AuthService.instance.getUserRole(),
            builder: (context, roleSnap) {
              if (!roleSnap.hasData) {
                return const Scaffold(
                  backgroundColor: Color(0xFFF5F6FA),
                  body: Center(
                    child: CircularProgressIndicator(color: Color(0xFFE53935)),
                  ),
                );
              }
              if (roleSnap.data == 'admin') {
                return const AdminDashboardScreen();
              }
              return const HomeScreen();
            },
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
