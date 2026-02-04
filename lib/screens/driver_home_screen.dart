import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'ride_details_screen.dart';
import 'profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'about.dart';

/// This StatefulWidget represents the home screen for a driver in the ride-sharing application.
/// It displays a list of pending ride requests and allows drivers to accept them.
/// It includes a toggle button to turn on/off ride request notifications and a
/// hamburger menu on the left providing access to an "About" section.

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

/// The state class for the [DriverHomeScreen] widget.
class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  StreamSubscription<QuerySnapshot>? _ridesSubscription;
  bool _notificationsEnabled =
  false; // Tracks the state of ride request notifications
  final GlobalKey<ScaffoldState> _scaffoldKey =
  GlobalKey<ScaffoldState>(); // Key for the Scaffold to manage the drawer

  /// Defines the basic theme for the application.
  final ThemeData _appTheme = ThemeData(
    primaryColor: const Color(0xFF105DFB),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontFamily: 'Readex Pro',
        color: Colors.white,
        fontSize: 22,
        letterSpacing: 0.0,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Readex Pro',
        color: Colors.black,
        fontSize: 18,
        letterSpacing: 0.0,
        fontWeight: FontWeight.bold,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Inter',
        color: Colors.black,
        fontSize: 14,
        letterSpacing: 0.0,
        fontWeight: FontWeight.normal,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF105DFB),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    ),
  );
  final GlobalKey<RefreshIndicatorState> _refreshKey =
  GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
    _setupFirebaseMessaging();
    if (_notificationsEnabled) {
      _listenForNewRides();
    }
  }

  /// Loads the user's notification preference (enabled/disabled) from local storage.
  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? false;
    });
  }

  /// Saves the user's notification preference (enabled/disabled) to local storage.
  Future<void> _saveNotificationPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance
        .collection('drivers')
        .doc(uid)
        .set({'notificationsEnabled': value}, SetOptions(merge: true));
    }
  }

  /// Sets up Firebase Cloud Messaging for handling push notifications.
  Future<void> _setupFirebaseMessaging() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      setState(() {
        _notificationsEnabled = true;
      });
      _saveNotificationPreference(true);
      _getTokenAndStore();
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print('User denied permission');
      setState(() {
        _notificationsEnabled = false;
      });
      _saveNotificationPreference(false);
      _showPermissionDeniedDialog();
    } else {
      print('User declined permission');
      setState(() {
        _notificationsEnabled = false;
      });
      _saveNotificationPreference(false);
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }

      if (mounted && _notificationsEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.notification?.title ?? 'New ride request!'),
          ),
        );
      }
      setState(() {});
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final rideId = message.data['rideId'];
      if (rideId != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RideDetailsScreen(
              rideId: rideId,
              userRole: 'driver',
            ),
          ),
        );
      }
    });

    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        final rideId = message.data['rideId'];
        if (rideId != null && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RideDetailsScreen(
                rideId: rideId,
                userRole: 'driver',
              ),
            ),
          );
        }
      }
    });

    _messaging.onTokenRefresh.listen((newToken) async {
      print('New FCM Token: $newToken');
      await _storeToken(newToken);
    });
  }

  /// Retrieves the current FCM token and stores it in the 'driverTokens' collection in Firestore.
  Future<void> _getTokenAndStore() async {
    String? token = await _messaging.getToken();
    if (token != null) {
      print('FCM Token: $token');
      await _storeToken(token);
    }
  }

  /// Stores the provided FCM [token] in the 'driverTokens' collection in Firestore.
  Future<void> _storeToken(String token) async {
    try {
      await _firestore.collection('driverTokens').doc(_auth.currentUser!.uid).set({
        'token': token,
      });
    } catch (e) {
      print("Error storing token: $e");
    }
  }

  /// Starts listening for new pending ride requests from Firestore.
  void _listenForNewRides() {
    _ridesSubscription = _firestore
        .collection('ride_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added && _notificationsEnabled) {
          _showNewRideNotification(change.doc.id);
        }
      }
      if (mounted) {
        setState(() {});
      }
    });
  }

  /// Shows a [SnackBar] notification to the driver when a new ride request is available.
  void _showNewRideNotification(String rideId) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New Ride Request: $rideId'),
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => RideDetailsScreen(
                    rideId: rideId,
                    userRole: 'driver',
                  ),
                ),
              );
            },
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  /// Displays an [AlertDialog] to inform the user that notification permissions have been denied.
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Permission Denied'),
        content: const Text(
          'Please enable notifications in your device settings to receive ride requests.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              // Placeholder for opening app settings.
              print("Open App Settings (Not implemented in this example)");
              Navigator.pop(context);
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  /// Updates the status of a ride request in Firestore to 'accepted'.
  Future<void> _acceptRide(String rideId) async {
    try {
      await _firestore.collection('ride_requests').doc(rideId).update({
        'status': 'accepted',
        'driverId': _auth.currentUser!.uid,
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RideDetailsScreen(
              rideId: rideId,
              userRole: 'driver',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept ride: $e')),
        );
      }
    }
  }

  /// Returns a [Stream] of pending ride requests from the 'ride_requests' collection in Firestore.
  Stream<QuerySnapshot> _getRides() {
    return _firestore
        .collection('ride_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  /// Handles the refresh indicator's action.
  Future<void> _handleRefresh() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _appTheme,
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: _appTheme.primaryColor,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          title: Text(
            'Available Ride Requests',
            style: _appTheme.textTheme.headlineMedium!,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  const Text('Notifications',
                      style: TextStyle(color: Colors.white)),
                  Switch(
                    value: _notificationsEnabled,
                    onChanged: (bool value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                      _saveNotificationPreference(value);
                      if (_notificationsEnabled) {
                        _listenForNewRides();
                        _getTokenAndStore();
                      } else {
                        _ridesSubscription?.cancel();
                      }
                    },
                    activeColor: Colors.white70,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.person, color: Colors.white),
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
          centerTitle: true,
          elevation: 0,
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: _appTheme.primaryColor,
                ),
                child: Text(
                  'Driver Menu',
                  style: _appTheme.textTheme.headlineMedium!,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutWidget(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        body: RefreshIndicator(
          key: _refreshKey,
          onRefresh: _handleRefresh,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: _getRides(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No pending ride requests',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey),
                    ),
                  );
                }

                final rides = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: rides.length,
                  itemBuilder: (context, index) {
                    final ride = rides[index];
                    final data = ride.data() as Map<String, dynamic>;

                    return _buildRideRequestCard(
                        context,
                        ride.id,
                        data['pickup'],
                        data['dropoff'],
                        data['price']);
                  },
                );
              },
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _handleRefresh,
          backgroundColor: _appTheme.primaryColor,
          child: const Icon(Icons.refresh, color: Colors.white),
        ),
      ),
    );
  }

  /// Builds a card widget to display individual ride request information.
  Widget _buildRideRequestCard(
      BuildContext context, String rideId, String pickup, String dropoff,
      dynamic price) {
    double actualPrice = 0.0;
    if (price != null) {
      if (price is num) {
        actualPrice = price.toDouble();
      } else {
        try {
          actualPrice = double.parse(price.toString());
        } catch (e) {
          print(
              "Error: Invalid price format.  Using default value of 0.0.  Price value: $price");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid price data received.')),
            );
          }
        }
      }
    }
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 8, 0, 8),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 4,
              color: const Color(0x1A000000),
              offset: const Offset(0, 2),
            )
          ],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ride Request',
                    style: _appTheme.textTheme.titleMedium!,
                  ),
                  Text(
                    '\$${actualPrice.toStringAsFixed(2)}',
                    style: _appTheme.textTheme.bodyMedium!
                        .copyWith(color: const Color(0xFF5A5C60)),
                  ),
                ],
              ),
              const Divider(
                thickness: 1,
                color: Color(0xFFE0E3E7),
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF105DFB),
                    size: 20,
                  ),
                  Text(
                    ' Pickup: ',
                    style: _appTheme.textTheme.bodyMedium!
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  Expanded(
                    child: Text(
                      pickup,
                      style: _appTheme.textTheme.bodyMedium!,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFFEE8B60),
                    size: 20,
                  ),
                  Text(
                    ' Dropoff: ',
                    style: _appTheme.textTheme.bodyMedium!
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  Expanded(
                    child: Text(
                      dropoff,
                      style: _appTheme.textTheme.bodyMedium!,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _acceptRide(rideId),
                    style: _appTheme.elevatedButtonTheme.style,
                    child: const Text('Accept',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

