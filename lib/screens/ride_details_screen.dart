import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'rider_home_screen.dart'; // Import your home screens
import 'driver_home_screen.dart';

class RideDetailsScreen extends StatefulWidget {
  final String rideId;
  final String userRole;

  const RideDetailsScreen({
    super.key,
    required this.rideId,
    required this.userRole,
  });

  @override
  State<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends State<RideDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _markRideAsCompleted() async {
    try {
      await _firestore.collection('ride_requests').doc(widget.rideId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride marked as completed!')),
        );

        // Use pushReplacement to avoid going back to this screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => widget.userRole == 'rider'
                ? const RiderHomeScreen() // Use your actual Home Screen
                : const DriverHomeScreen(), // Use your actual Home Screen
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update ride status: $e')),
        );
      }
    }
  }

  Future<void> _launchPhoneDialer(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    // print('Attempting to call: ${phoneUri.toString()}'); // Keep for Debugging
    try {
      if (await canLaunchUrl(Uri.parse(phoneUri.toString()))) { // Use canLaunchUrl
        await launchUrl(Uri.parse(phoneUri.toString())); // Use launchUrl
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch dialer')),
          );
        }
      }
    } catch (e) {
      // print('Error launching dialer: $e');  // Keep for Debugging
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch dialer: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2797FF),
        automaticallyImplyLeading: true,
        title: const Text(
          'Ride Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => setState(() {}),
          ),
        ],
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('ride_requests').doc(widget.rideId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Ride not found'));
          }

          final rideDetails = snapshot.data!.data() as Map<String, dynamic>;

          //check the status.
          if (rideDetails['status'] == 'completed')
          {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => widget.userRole == 'rider'
                      ? const RiderHomeScreen()
                      : const DriverHomeScreen(),
                ),
              );
            });
          }

          return FutureBuilder<Map<String, dynamic>?>(
            future: _fetchCounterpartDetails(rideDetails),
            builder: (context, counterpartSnapshot) {
              if (counterpartSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final counterpartDetails = counterpartSnapshot.data;

              return Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  // Location Details Card
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 24),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2797FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Pickup Location
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'PICKUP LOCATION',
                                        style: TextStyle(
                                          color: Color(0xFFE0E3E7),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        rideDetails['pickup'] ?? 'Not specified',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ].divide(const SizedBox(width: 12)),
                            ),
                            const SizedBox(height: 16),
                            // Drop-off Location
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'DROP-OFF LOCATION',
                                        style: TextStyle(
                                          color: Color(0xFFE0E3E7),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        rideDetails['dropoff'] ?? 'Not specified',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ].divide(const SizedBox(width: 12)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE0E3E7)),

                  // Counterpart Details
                  if (counterpartDetails != null)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(16, 24, 16, 24),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.userRole == 'rider' ? 'Driver Details' : 'Rider Details',
                                  style: const TextStyle(
                                    color: Color(0xFF161C24),
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE0E3E7),
                                        shape: BoxShape.circle,
                                        image: counterpartDetails['photoUrl'] != null
                                            ? DecorationImage(
                                          fit: BoxFit.cover,
                                          image: NetworkImage(
                                            counterpartDetails['photoUrl'],
                                          ),
                                        )
                                            : null,
                                      ),
                                      child: counterpartDetails['photoUrl'] == null
                                          ? const Icon(Icons.person, size: 40, color: Colors.grey)
                                          : null,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            counterpartDetails['name'] ?? 'Unknown',
                                            style: const TextStyle(
                                              color: Color(0xFF161C24),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          if (counterpartDetails['rating'] != null)
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.star_rounded,
                                                  color: Color(0xFF27AE52),
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  counterpartDetails['rating'].toString(),
                                                  style: const TextStyle(
                                                    color: Color(0xFF161C24),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          if (widget.userRole == 'rider' &&
                                              counterpartDetails['carModel'] != null &&
                                              counterpartDetails['carColor'] != null)
                                            Text(
                                              '${counterpartDetails['carModel']} • ${counterpartDetails['carColor']}',
                                              style: const TextStyle(
                                                color: Color(0xFF636F81),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          if (widget.userRole == 'rider' &&
                                              counterpartDetails['numberPlate'] != null)
                                            Text(
                                              counterpartDetails['numberPlate'],
                                              style: const TextStyle(
                                                color: Color(0xFF636F81),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                        ].where((child) => child != null).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                // Phone Number Section
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'PHONE NUMBER',
                                              style: TextStyle(
                                                color: Color(0xFF636F81),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              counterpartDetails['phone'] ?? 'Not available',
                                              style: const TextStyle(
                                                color: Color(0xFF161C24),
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            if (counterpartDetails['phone'] != null &&
                                                counterpartDetails['phone'].isNotEmpty) {
                                              _launchPhoneDialer(counterpartDetails['phone']);
                                            } else {
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                      content: Text('Phone number not available')),
                                                );
                                              }
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF2797FF),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(24),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                          ),
                                          child: const Text(
                                            'Call',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    const Expanded(
                      child: Center(
                        child: Text('No counterpart details available'),
                      ),
                    ),
                  const Divider(height: 1, color: Color(0xFFE0E3E7)),

                  // Action Button
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 32),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 8,
                            color: Color(0x19000000),
                            offset: Offset(0, -2),
                          )
                        ],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: ElevatedButton(
                        onPressed: rideDetails['status'] == 'accepted'
                            ? _markRideAsCompleted
                            : null, // Disable if not accepted
                        style: ElevatedButton.styleFrom(
                          backgroundColor:  rideDetails['status'] == 'accepted' ? const Color(0xFF2797FF) : const Color(0x19FF5963) , //make button blue if ride is accepted.
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side:  rideDetails['status'] != 'accepted' ? const BorderSide(
                              color: Color(0xFFEE4444),
                              width: 1,
                            ) : BorderSide.none,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child:  Text(
                          rideDetails['status'] == 'accepted' ? 'Mark as Completed' : 'Cancel Ride',
                          style: TextStyle(
                            color:  rideDetails['status'] == 'accepted' ?  Colors.white : const Color(0xFFEE4444),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>?> _fetchCounterpartDetails(
      Map<String, dynamic> rideDetails) async {
    try {
      final counterpartId = widget.userRole == 'rider'
          ? rideDetails['driverId']
          : rideDetails['riderId'];

      if (counterpartId != null) {
        final counterpartDoc = await _firestore.collection('users').doc(counterpartId).get();
        if (counterpartDoc.exists) {
          return counterpartDoc.data()!;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching counterpart details: $e')),
        );
      }
    }
    return null;
  }
}

// Extension for adding space between widgets in a list
extension ListSpaceBetweenExtension on List<Widget> {
  List<Widget> divide(Widget spacer) {
    return length <= 1
        ? this
        : [
      for (int i = 0; i < length; i++) ...[
        this[i],
        if (i != length - 1) spacer,
      ],
    ];
  }
}
