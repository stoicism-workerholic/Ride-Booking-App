import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Import for making HTTP requests
import 'package:google_fonts/google_fonts.dart';
import 'ride_details_screen.dart';
import 'profile_screen.dart';
import 'about.dart'; // Import your About Screen

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  bool _isLoading = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); // Key for the scaffold
  String _userName = ''; // To store the user's name

  // Cloud Function URL (Replace with your actual Cloud Function URL)
  final String _cloudFunctionUrl =
      'https://us-central1-ridebook-3a6b3.cloudfunctions.net/sendNewRideRequestNotification'; // Replace this

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  // Function to load the user's name from Firestore
  Future<void> _loadUserName() async {
    try {
      final userDoc =
      await _firestore.collection('users').doc(_auth.currentUser!.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        setState(() {
          _userName = userData['name'] ??
              ''; // Use an empty string if name is null
        });
      }
    } catch (e) {
      // Handle error, perhaps show a snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user name: $e')),
        );
      }
      print('Error loading user name: $e');
    }
  }

  Future<void> _createRideRequest() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final rideRef = await _firestore.collection('ride_requests').add({
          'pickup': _pickupController.text.trim(),
          'dropoff': _dropoffController.text.trim(),
          'riderId': _auth.currentUser!.uid,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Call the Cloud Function to notify drivers
        // await _notifyDriversOfNewRide(rideRef.id); // Await the function call

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RideDetailsScreen(
                rideId: rideRef.id,
                userRole: 'rider',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create ride request: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // Function to call the Cloud Function
  // Future<void> _notifyDriversOfNewRide(String rideId) async {
  //   try {
  //     final response = await http.post(
  //       Uri.parse(_cloudFunctionUrl),
  //       headers: <String, String>{
  //         'Content-Type': 'application/json; charset=UTF-8',
  //       },
  //       body: jsonEncode(<String, String>{
  //         'rideId': rideId,
  //       }),
  //     );
  //
  //     if (response.statusCode != 200) {
  //       print(
  //           'Failed to call Cloud Function: ${response.statusCode} ${response.body}');
  //       // Consider showing a user-friendly message, or logging to a server.
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //               content: Text(
  //                   'Failed to notify drivers. Please try again.')), // Keep message general
  //         );
  //       }
  //     } else {
  //       print('Cloud Function called successfully');
  //     }
  //   } catch (e) {
  //     print('Error calling Cloud Function: $e');
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //             content: Text(
  //                 'Network error.  Please check your connection.')), // Keep message general
  //       );
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    // ... (rest of your RiderHomeScreen UI code)
    const primaryColor = Color(0xFF105DFB);

    return Scaffold(
      key: _scaffoldKey, // Assign the GlobalKey to the Scaffold
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer(); // Open the drawer
          },
        ),
        title: const Text(
          'Rider Login',
          style: TextStyle(
            fontFamily: 'Inter Tight',
            color: Colors.white,
            letterSpacing: 0.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
        centerTitle: false,
        elevation: 2,
        backgroundColor: primaryColor,
      ),
      drawer: _buildDrawer(context), // Build the drawer
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0x4C4B39EF),
                    primaryColor,
                  ],
                  stops: const [0.2, 0.8],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Roam',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter Tight',
                          color: Colors.white,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.bold,
                          fontSize: 30.0,
                        )),
                    // Added Text widget for "Hello, [Username]"
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _userName.isNotEmpty ? 'Hello, $_userName!' : 'Hello!',
                        // Use a ternary operator to display a default message if the username is empty.
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lobster(
                          // Use GoogleFonts
                          color: Colors.white,
                          letterSpacing: 0.0,
                          fontSize: 20.0, // Increased font size
                          fontWeight: FontWeight.w400, // Added fontWeight
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: const Text(
                        'Where would you like to go today?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white,
                          letterSpacing: 0.0,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 5,
                            color: Color(0x1A000000),
                            offset: Offset(0, 2),
                          )
                        ],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                'Pickup Location',
                                style: TextStyle(
                                  fontFamily: 'Inter Tight',
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18.0,
                                ),
                              ),
                            ),
                            TextFormField(
                              controller: _pickupController,
                              decoration: InputDecoration(
                                hintText: 'Enter your pickup location',
                                hintStyle: const TextStyle(
                                  fontFamily: 'Inter',
                                  color: Color(0xFF9E9E9E),
                                  letterSpacing: 0.0,
                                  fontSize: 14.0,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors.transparent,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors.transparent,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding:
                                const EdgeInsets.fromLTRB(16, 12, 16, 12),
                                prefixIcon: const Icon(
                                  Icons.location_on_outlined,
                                  color: primaryColor,
                                  size: 24,
                                ),
                              ),
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                letterSpacing: 0.0,
                                fontSize: 14.0,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a pickup location';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 5,
                            color: Color(0x1A000000),
                            offset: Offset(0, 2),
                          )
                        ],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                'Drop-off Location',
                                style: TextStyle(
                                  fontFamily: 'Inter Tight',
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18.0,
                                ),
                              ),
                            ),
                            TextFormField(
                              controller: _dropoffController,
                              decoration: InputDecoration(
                                hintText: 'Enter your destination',
                                hintStyle: const TextStyle(
                                  fontFamily: 'Inter',
                                  color: Color(0xFF9E9E9E),
                                  letterSpacing: 0.0,
                                  fontSize: 14.0,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors.transparent,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors.transparent,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding:
                                const EdgeInsets.fromLTRB(16, 12, 16, 12),
                                prefixIcon: const Icon(
                                  Icons.location_on,
                                  color: primaryColor,
                                  size: 24,
                                ),
                              ),
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                letterSpacing: 0.0,
                                fontSize: 14.0,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a drop-off location';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _createRideRequest,
                      label: const Text('Search for Driver',
                          style: TextStyle(
                              fontFamily: 'Inter Tight',
                              color: Colors.white,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      icon: const Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 24,
                      ),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          backgroundColor: primaryColor,
                          elevation: 2,
                          minimumSize: const Size(double.infinity, 55)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to build the Drawer
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF105DFB), // Use your primary color
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Roam',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter Tight'
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rider',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Inter'
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile',  style: TextStyle(fontFamily: 'Inter')),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About',  style: TextStyle(fontFamily: 'Inter')),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutWidget(), // Use the AboutWidget
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout',  style: TextStyle(fontFamily: 'Inter')),
            onTap: () {
              // Implement your logout logic here
              _signOut(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await _auth.signOut();
      // Navigate to the login screen (replace '/login' with your actual login route)
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }
}

