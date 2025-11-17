import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/news_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'services/preferences_service.dart';
import 'services/fcm_service.dart'
    show FCMService, firebaseMessagingBackgroundHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };

  // Setup error widget builder
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              const Text(
                'Terjadi Kesalahan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                details.exception.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  };

  // Initialize Firebase dengan timeout untuk memastikan tidak blocking terlalu lama
  try {
    await Future.any([
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
      Future.delayed(const Duration(seconds: 5), () {
        debugPrint('Firebase initialization timeout - continuing anyway');
        throw TimeoutException('Firebase initialization timeout');
      }),
    ]);

    if (Firebase.apps.isNotEmpty) {
      debugPrint('Firebase initialized successfully');

      // FCM hanya untuk mobile (Android/iOS), tidak untuk web
      if (!kIsWeb) {
        try {
          // Setup FCM background handler (hanya untuk mobile)
          FirebaseMessaging.onBackgroundMessage(
            firebaseMessagingBackgroundHandler,
          );

          // Initialize FCM (hanya untuk mobile) dengan timeout
          await Future.any([
            FCMService.initialize(),
            Future.delayed(const Duration(seconds: 3), () {
              debugPrint('FCM initialization timeout - continuing anyway');
              throw TimeoutException('FCM initialization timeout');
            }),
          ]);
          debugPrint('FCM initialized successfully');
        } catch (e) {
          debugPrint('Error initializing FCM: $e');
          // Lanjutkan meskipun FCM gagal
        }
      }
    }
  } on TimeoutException catch (e) {
    debugPrint('Firebase initialization timeout: $e');
    // Lanjutkan meskipun timeout
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
    // Lanjutkan meskipun Firebase gagal (untuk development)
  }

  // Jalankan aplikasi
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NewsProvider()),
      ],
      child: MaterialApp(
        title: 'Daya Assist',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/onboarding-check': (context) => const OnboardingCheckWrapper(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/auth': (context) => const AuthWrapper(),
        },
      ),
    );
  }
}

class OnboardingCheckWrapper extends StatelessWidget {
  const OnboardingCheckWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: PreferencesService.isOnboardingCompleted(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Handle error
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/auth');
                    },
                    child: const Text('Lanjutkan'),
                  ),
                ],
              ),
            ),
          );
        }

        // Jika onboarding belum selesai, tampilkan onboarding
        if (snapshot.data == false) {
          return const OnboardingScreen();
        }

        // Jika sudah selesai, lanjut ke auth
        return const AuthWrapper();
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Gunakan Consumer untuk menghindari error jika Provider belum siap
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        try {
          // Jika user sudah login, tampilkan home screen (tanpa batasan)
          if (authProvider.isAuthenticated) {
            return const HomeScreen();
          }

          // Jika belum login, allow guest access (bisa coba fitur dengan batasan 3x)
          return const HomeScreen(); // Langsung ke home screen untuk guest access
        } catch (e) {
          // Fallback jika ada error
          debugPrint('Error in AuthWrapper: $e');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('Error: $e'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/');
                    },
                    child: const Text('Kembali ke Splash'),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
