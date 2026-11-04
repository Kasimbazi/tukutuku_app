import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'services/notification_service.dart'; // Uncomment once notification_service.dart is implemented
import 'services/api_service.dart';
import 'services/navigation_service.dart';
import 'models/delivery_model.dart';
import 'screens/driver_screen.dart';
import 'screens/customer_history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // try {
  //   if (Firebase.apps.isEmpty) {
  //     await Firebase.initializeApp();
  //   }
  // } catch (e) {
  //   debugPrint("Firebase initialization skipped or failed: $e");
  // }

  runApp(const TukutukuApp());
}

class TukutukuApp extends StatelessWidget {
  const TukutukuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tukutuku Express',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF00E676),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E676),
          secondary: Color(0xFF2979FF),
          surface: Color(0xFF1E1E1E),
        ),
      ),
      home: const MainNavigationHub(),
    );
  }
}

class MainNavigationHub extends StatefulWidget {
  const MainNavigationHub({super.key});

  @override
  State<MainNavigationHub> createState() => _MainNavigationHubState();
}

class _MainNavigationHubState extends State<MainNavigationHub> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const BookingScreen(),
    const CustomerHistoryScreen(),
    const DriverScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: const Color(0xFF00E676),
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Book'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Driver Feed'),
        ],
      ),
    );
  }
}

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  String _selectedCargoType = 'Standard Tukutuku (Up to 500kg)';
  bool _isLoading = false;

  void _submitOrder() async {
    if (_pickupController.text.isEmpty || _dropoffController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in pickup and dropoff locations')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.createDelivery(
        pickup: _pickupController.text,
        dropoff: _dropoffController.text,
        cargoType: _selectedCargoType,
      );

      final deliveryData = Delivery.fromJson(response['delivery']);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TrackingScreen(delivery: deliveryData),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tukutuku Dispatch'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Where are we moving cargo?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _pickupController,
              decoration: InputDecoration(
                labelText: 'Pickup Location (e.g. Kikuubo)',
                prefixIcon: const Icon(Icons.my_location, color: Color(0xFF00E676)),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dropoffController,
              decoration: InputDecoration(
                labelText: 'Drop-off Destination (e.g. Nakawa Market)',
                prefixIcon: const Icon(Icons.location_on, color: Colors.redAccent),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedCargoType,
              dropdownColor: const Color(0xFF1E1E1E),
              decoration: InputDecoration(
                labelText: 'Cargo Capacity',
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: <String>[
                'Standard Tukutuku (Up to 500kg)',
                'Heavy Duty Cargo (Up to 800kg)',
                'Enclosed Box (Weatherproof)'
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() => _selectedCargoType = newValue!);
              },
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isLoading ? null : _submitOrder,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text(
                      'Request Tukutuku',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class TrackingScreen extends StatelessWidget {
  final Delivery delivery;

  const TrackingScreen({super.key, required this.delivery});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${delivery.id} Status'),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DISPATCH SUMMARY', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.my_location, color: Color(0xFF00E676), size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(delivery.pickupLocation, style: const TextStyle(fontSize: 16))),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Text('│', style: TextStyle(color: Colors.grey)),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(delivery.dropoffLocation, style: const TextStyle(fontSize: 16))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Estimated Fare:', style: TextStyle(fontSize: 18, color: Colors.grey)),
                Text(
                  'UGX ${delivery.fareUgx.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF00E676)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Status:', style: TextStyle(fontSize: 18, color: Colors.grey)),
                Chip(
                  label: Text(delivery.status.toUpperCase(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  backgroundColor: const Color(0xFF00E676),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2979FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.navigation),
                label: const Text(
                  'Open Route in Google Maps',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  NavigationService.launchNavigation(destinationAddress: delivery.dropoffLocation);
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}