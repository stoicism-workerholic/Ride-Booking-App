import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

/// A simple "About" screen for the ride-sharing application.
/// Displays information about the app, its features, and the developers.
class AboutWidget extends StatelessWidget {
  const AboutWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Define a more standard Flutter theme. You can customize this.
    final ThemeData appTheme = ThemeData(
      primaryColor: const Color(0xFF105DFB), //  primary color
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF105DFB)),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.readexPro(
          //  displayLarge
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Colors.black,
          letterSpacing: -1.2,
        ),
        headlineMedium: GoogleFonts.readexPro(
          // headlineMedium
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Colors.black,
          letterSpacing: -0.8,
        ),
        bodyLarge: GoogleFonts.inter(
          // bodyLarge
          fontSize: 18,
          color: Colors.black87,
          height: 1.6, // Increased line height for better readability
        ),
        bodyMedium: GoogleFonts.inter(
          // bodyMedium
          fontSize: 16,
          color: Colors.black87,
          height: 1.5,
        ),
        titleLarge: GoogleFonts.readexPro(
          // titleLarge
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.black,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardTheme(
        // card theme
        elevation: 6, // Slightly increased elevation
        shadowColor: Colors.black.withOpacity(0.1), // Added shadow color
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)), // More rounded corners
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        // elevated button theme
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF105DFB),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
              horizontal: 32, vertical: 16), // Increased padding
          shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(16)), // More rounded corners
          elevation: 3, // Added elevation
          shadowColor: Colors.black.withOpacity(0.08),
        ),
      ),
      scaffoldBackgroundColor:
          Colors.white, // scaffold background
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight
                .w600), // Increased font weight
      ),
      dividerTheme: const DividerThemeData(
        //divider
        thickness: 1.2,
        color: Color(0xFFE0E0E0),
        space: 24,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            //  Use explicit pop with a check
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              // Navigate to the home screen
              Navigator.of(context).pushReplacementNamed('/');
            }
          },
        ),
      ),
      backgroundColor: appTheme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24), // Added vertical padding
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'About Our App',
                style: appTheme.textTheme.displayLarge,
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to our ride-sharing application, designed to connect riders and drivers seamlessly and efficiently.  We are committed to providing a safe, reliable, and convenient transportation solution for everyone.',
                style: appTheme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              Text(
                'Key Features',
                style: appTheme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              _buildFeatureTile(
                context,
                'Easy Ride Booking',
                'Book a ride with just a few taps. Enter your pickup and dropoff locations, and get matched with a driver quickly.',
                Icons.directions_car,
              ),
              _buildFeatureTile(
                context,
                'Real-time Tracking',
                'Track your driver\'s location in real-time on the map.  Know exactly when your driver will arrive.',
                Icons.location_on,
              ),
              _buildFeatureTile(
                context,
                'Secure Payments',
                'Pay for your ride securely within the app using various payment methods.  Your financial information is protected.',
                Icons.payment,
              ),
              _buildFeatureTile(
                context,
                'Driver Profiles',
                'View driver profiles, ratings, and vehicle information before you start your ride.',
                Icons.person,
              ),
              const SizedBox(height: 32),
              Text(
                'Contact Us',
                style: appTheme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              Text(
                "We'd love to hear from you! If you have any questions, feedback, or suggestions, please don't hesitate to reach out to us.",
                style: appTheme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.email, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('Email: leeshaprasad2555@gmail.com'),
                ],
              ),
              const SizedBox(height: 8),

// inside your build method or widget
              Row(
                children: [
                  Icon(Icons.phone, color: Colors.grey),
                  SizedBox(width: 8),
                  RichText(
                    text: TextSpan(
                      text: 'Phone: ',
                      style: TextStyle(color: Colors.black),
                      children: [
                        TextSpan(
                          text: '+679 9861557',
                          style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              final Uri uri =
                                  Uri(scheme: 'tel', path: '+6799861557');
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              } else {
                                throw 'Could not launch dialer';
                              }
                            },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Privacy Policy',
                style: appTheme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  style: appTheme.textTheme.bodyMedium?.copyWith(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.bold, // Added bold for emphasis
                  ),
                  text: 'View Privacy Policy',
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      final Uri privacyPolicyUrl = Uri.parse(
                          'https://github.com/stoicism-workerholic/Roam-privacy-policy/blob/main/privacy-policy');

                      if (await canLaunchUrl(privacyPolicyUrl)) {
                        await launchUrl(privacyPolicyUrl);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not launch the privacy policy URL.'),
                          ),
                        );
                      }
                    },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a styled card for displaying a feature.
  Widget _buildFeatureTile(
      BuildContext context, String title, String description, IconData icon) {
    final ThemeData theme = Theme.of(context);
    return Card(
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20), // Increased padding
        child: Row(
          children: [
            Icon(icon, color: theme.primaryColor, size: 36), // Increased size
            const SizedBox(width: 20), // Increased spacing
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a styled card for displaying a team member.
  Widget _buildTeamMemberTile(BuildContext context, String name, String title,
      String bio, String imageUrl) {
    final ThemeData theme = Theme.of(context);
    //check the image URL
    if (!Uri.parse(imageUrl).isAbsolute) {
      imageUrl =
          'https://via.placeholder.com/150'; // Use a default image or an empty string
    }
    return Card(
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20), // Increased padding
        child: Row(
          children: [
            CircleAvatar(
              radius: 50, // Increased radius
              backgroundImage: NetworkImage(imageUrl),
              onBackgroundImageError: (exception, stackTrace) {
                // Handle the error here.  A common approach is to display a placeholder.
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey, // Or any color you want.
                  child: const Icon(Icons.error), // show an error icon
                );
              },
            ),
            const SizedBox(width: 20), // Increased spacing
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(title, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 12), // Increased spacing
                  Text(
                    bio,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}