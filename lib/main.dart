import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Added google_fonts import
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/rider_home_screen.dart';
import 'screens/driver_home_screen.dart';
import 'screens/intropage.dart'; // Import the IntroPage
import 'screens/about.dart'; // Import the AboutWidget

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await setupFirebaseMessaging();
    await requestNotificationPermissions();
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final userRole = prefs.getString('userRole') ?? 'rider';
    runApp(MyApp(isLoggedIn: isLoggedIn, userRole: userRole));
  } catch (e) {
    print('Error during Firebase initialization: $e');
    runApp(const ErrorApp());
  }
}

Future<void> requestNotificationPermissions() async {
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
}

Future<void> setupFirebaseMessaging() async {
  final messaging = FirebaseMessaging.instance;
  final token = await messaging.getToken();
  print('FCM Token: $token');
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');
    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
    }
    final rideId = message.data['rideId'];
    if (rideId != null) {
      print('Navigate to ride details screen for rideId: $rideId');
    }
  });
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('A notification was tapped!');
    print('Message data: ${message.data}');
    final rideId = message.data['rideId'];
    if (rideId != null) {
      print('Navigate to ride details screen for rideId: $rideId');
    }
  });
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String userRole;
  const MyApp({super.key, required this.isLoggedIn, required this.userRole});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ride Booking App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/registration': (context) => const RegistrationScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/rider_home': (context) => const RiderHomeScreen(),
        '/driver_home': (context) => const DriverHomeScreen(),
        '/about': (context) => const AboutWidget(), // Add the AboutWidget route
      },
// Set IntroPage as the home. Navigation logic is in the IntroPage.
      home: const IntropageWidget(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'An error occurred while initializing the app.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  main();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

