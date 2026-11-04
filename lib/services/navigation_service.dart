import 'package:url_launcher/url_launcher.dart';

class NavigationService {
  // Launch turn-by-turn navigation in Google Maps
  static Future<void> launchNavigation({required String destinationAddress}) async {
    // Encode destination string for URL query
    final encodedDestination = Uri.encodeComponent(destinationAddress);
    
    // Google Maps Universal URL scheme for navigation
    final Uri mapUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$encodedDestination&travelmode=driving');

    try {
      if (await canLaunchUrl(mapUri)) {
        await launchUrl(mapUri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch maps application.');
      }
    } catch (e) {
      throw Exception('Navigation error: $e');
    }
  }
}