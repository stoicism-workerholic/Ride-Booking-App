import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'registration_screen.dart';
import 'rider_home_screen.dart';
import 'driver_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'rider'; // Default role
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _setupFCMTokenListener();
    _setupFCMForegroundHandler();
    _setupFCMBackgroundHandler();
  }

  Future<void> _signIn() async {
    if (!mounted) return;

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      ScaffoldMessenger.of(context).clearSnackBars();

      try {
        final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (credential.user == null) {
          throw FirebaseAuthException(
            code: 'null-user',
            message: 'Authentication failed - no user returned',
          );
        }

        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .get();

        if (!userDoc.exists || userDoc.data()!['role'] != _selectedRole) {
          throw FirebaseAuthException(
            code: 'wrong-role',
            message: 'Please select the correct role for your account',
          );
        }

        // Save login state and user role
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userRole', _selectedRole);

        // Save FCM token to Firestore
        await saveFCMTokenToFirestore(credential.user!.uid);

        // Subscribe drivers to the 'available_rides' topic
        if (_selectedRole == 'driver') {
          await subscribeDriverToTopic();
        }

        // Navigate to the appropriate home screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => _selectedRole == 'rider'
                ? const RiderHomeScreen()
                : const DriverHomeScreen(),
          ),
              (route) => false,
        );
      } on FirebaseAuthException catch (e) {
        // Show specific error message if email or password is incorrect
        String errorMessage = 'An error occurred';

        if (e.code == 'user-not-found' || e.code == 'wrong-password') {
          errorMessage = 'Wrong credentials';
        } else {
          errorMessage = e.message ?? 'An error occurred';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // Save FCM token to Firestore
  Future<void> saveFCMTokenToFirestore(String userId) async {
    final messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();

    if (token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({'fcmToken': token}, SetOptions(merge: true));
    }
  }

  // Subscribe drivers to the 'available_rides' topic
  Future<void> subscribeDriverToTopic() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.subscribeToTopic('available_rides');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  // Listen for FCM token refresh
  void _setupFCMTokenListener() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({'fcmToken': newToken}, SetOptions(merge: true));
      }
    });
  }

  // Handle foreground notifications
  void _setupFCMForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground Notification: ${message.notification?.title}');
      // Show a local notification or update the UI
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message.notification?.title ?? 'New notification'),
        ),
      );
    });
  }

  // Handle background notifications
  void _setupFCMBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Background notification handler
  Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print('Background Notification: ${message.notification?.title}');
    // Handle background notifications
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F4F8),
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 8),
                          child: Text(
                            'Welcome Back',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              // Replace FlutterFlowTheme
                              fontFamily: 'Urbanist',
                              color: Color(0xFF101213),
                              fontSize: 32,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 32),
                          child: Text(
                            'Sign in to continue',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              // Replace FlutterFlowTheme
                              fontFamily: 'Manrope',
                              color: Color(0xFF57636C),
                              fontSize: 14,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: TextFormField(
                                controller: _emailController,
                                autofocus: false,
                                textCapitalization: TextCapitalization.none,
                                textInputAction: TextInputAction.next,
                                obscureText: false,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  labelStyle: const TextStyle(
                                    // Replace FlutterFlowTheme
                                    fontFamily: 'Manrope',
                                    color: Color(0xFF101213),
                                    fontSize: 14,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  hintStyle: const TextStyle(
                                    // Replace FlutterFlowTheme
                                    fontFamily: 'Manrope',
                                    color: Color(0xFF57636C),
                                    fontSize: 14,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE0E3E7),
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: Color(0xFF9489F5),
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: Color(0x00000000),
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: Color(0x00000000),
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                                style: const TextStyle(
                                  // Replace FlutterFlowTheme
                                  fontFamily: 'Manrope',
                                  color: Color(0xFF101213),
                                  fontSize: 14,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.normal,
                                ),
                                keyboardType: TextInputType.emailAddress,
                                cursorColor: const Color(0xFF9489F5),
                                validator: (value) =>
                                value!.isEmpty ? 'Please enter your email' : null,
                              ),
                            ),
                            const SizedBox(height: 20), // Added spacing
                            SizedBox(
                              width: double.infinity,
                              child: TextFormField(
                                controller: _passwordController,
                                autofocus: false,
                                textCapitalization: TextCapitalization.none,
                                textInputAction: TextInputAction.done,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  labelStyle: const TextStyle(
                                    // Replace FlutterFlowTheme
                                    fontFamily: 'Manrope',
                                    color: Color(0xFF101213),
                                    fontSize: 14,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  hintStyle: const TextStyle(
                                    // Replace FlutterFlowTheme
                                    fontFamily: 'Manrope',
                                    color: Color(0xFF57636C),
                                    fontSize: 14,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE0E3E7),
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: Color(0xFF9489F5),
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: Color(0x00000000),
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: Color(0x00000000),
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.all(16),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off),
                                    onPressed: () => setState(() =>
                                    _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                style: const TextStyle(
                                  // Replace FlutterFlowTheme
                                  fontFamily: 'Manrope',
                                  color: Color(0xFF101213),
                                  fontSize: 14,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.normal,
                                ),
                                cursorColor: const Color(0xFF9489F5),
                                validator: (value) => value!.isEmpty
                                    ? 'Please enter your password'
                                    : null,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'I am a:',
                                  style: const TextStyle(
                                    // Replace FlutterFlowTheme
                                    fontFamily: 'Manrope',
                                    color: Color(0xFF101213),
                                    fontSize: 14,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () =>
                                            setState(() => _selectedRole = 'rider'),
                                        child: Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: _selectedRole == 'rider'
                                                ? const Color(0xFFE0F7FA) // Light blue for rider
                                                : Colors.white,
                                            borderRadius:
                                            BorderRadius.circular(12),
                                            border: Border.all(
                                              color: const Color(0xFFE0E3E7),
                                              width: 1,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                              MainAxisAlignment.center,
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                                      8, 0, 8, 0),
                                                  child: Icon(
                                                    Icons.person,
                                                    color: _selectedRole ==
                                                        'rider'
                                                        ? const Color(
                                                        0xFF00897B) // Darker blue for selected
                                                        : const Color(0xFF9489F5),
                                                    size: 24,
                                                  ),
                                                ),
                                                Text(
                                                  'Rider',
                                                  style: TextStyle(
                                                    // Replace FlutterFlowTheme
                                                    fontFamily: 'Manrope',
                                                    color: _selectedRole ==
                                                        'rider'
                                                        ? const Color(
                                                        0xFF000000) // Black for selected
                                                        : const Color(0xFF101213),
                                                    fontSize: 14,
                                                    letterSpacing: 0.0,
                                                    fontWeight:
                                                    FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () =>
                                            setState(() => _selectedRole = 'driver'),
                                        child: Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: _selectedRole == 'driver'
                                                ? const Color(0xFFFFFDE7) // Light yellow for driver
                                                : Colors.white,
                                            borderRadius:
                                            BorderRadius.circular(12),
                                            border: Border.all(
                                              color: const Color(0xFFE0E3E7),
                                              width: 1,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                              MainAxisAlignment.center,
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                                      8, 0, 8, 0),
                                                  child: Icon(
                                                    Icons.directions_car,
                                                    color: _selectedRole ==
                                                        'driver'
                                                        ? const Color(
                                                        0xFFFFC107) // Darker yellow for selected
                                                        : const Color(0xFF9489F5),
                                                    size: 24,
                                                  ),
                                                ),
                                                Text(
                                                  'Driver',
                                                  style: TextStyle(
                                                    // Replace FlutterFlowTheme
                                                    fontFamily: 'Manrope',
                                                    color: _selectedRole ==
                                                        'driver'
                                                        ? const Color(
                                                        0xFF000000) // Black for selected
                                                        : const Color(0xFF101213),
                                                    fontSize: 14,
                                                    letterSpacing: 0.0,
                                                    fontWeight:
                                                    FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Padding(
                              padding:
                              const EdgeInsetsDirectional.fromSTEB(0, 24, 0, 0),
                              child: ElevatedButton(
                                // Replace FFButtonWidget
                                onPressed: _isLoading ? null : _signIn,
                                style: ElevatedButton.styleFrom(
                                  // Replace FFButtonOptions
                                  minimumSize:
                                  const Size(double.infinity, 56),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(12),
                                  ),
                                  backgroundColor:
                                  const Color(0xFF9489F5),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                                    : const Text(
                                  // Replace FlutterFlowTheme
                                  'Log In',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    color: Colors.white,
                                    fontSize: 16,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                              const EdgeInsetsDirectional.fromSTEB(0, 24, 0, 0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Don’t have an account?',
                                    style: const TextStyle(
                                      // Replace FlutterFlowTheme
                                      fontFamily: 'Manrope',
                                      color: Color(0xFF57636C),
                                      fontSize: 14,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  TextButton(
                                    // Replace FFButtonWidget
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                          const RegistrationScreen()),
                                    ),
                                    style: TextButton.styleFrom(
                                      // Replace FFButtonOptions
                                      padding: EdgeInsets.zero,
                                      minimumSize:
                                      const Size(100, 40),
                                    ),
                                    child: const Text(
                                      // Replace FlutterFlowTheme
                                      'Register',
                                      style: TextStyle(
                                        fontFamily: 'Manrope',
                                        color: Color(0xFF9489F5),
                                        fontSize: 14,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

