import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/navigation_service.dart';
import '../models/delivery_model.dart';

class DriverScreen extends StatefulWidget {
  const DriverScreen({super.key});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  late Future<List<Delivery>> _futureDeliveries;
  Timer? _pollingTimer;
  bool _isOnline = true; // <--- Driver availability state

  @override
  void initState() {
    super.initState();
    _loadDeliveries();

    // Poll for new orders every 5 seconds only when online
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && _isOnline) {
        _loadDeliveries(isBackground: true);
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _loadDeliveries({bool isBackground = false}) {
    if (!_isOnline) return;

    if (!isBackground) {
      setState(() {
        _futureDeliveries = ApiService.getDeliveries().then((data) {
          return data.map((json) => Delivery.fromJson(json)).toList();
        });
      });
    } else {
      ApiService.getDeliveries().then((data) {
        if (mounted && _isOnline) {
          setState(() {
            _futureDeliveries = Future.value(data.map((json) => Delivery.fromJson(json)).toList());
          });
        }
      }).catchError((_) {});
    }
  }

  void _toggleOnlineStatus(bool value) {
    setState(() {
      _isOnline = value;
      if (_isOnline) {
        _loadDeliveries(); // Refresh immediately when going back online
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isOnline ? 'You are now ONLINE & ready for dispatches' : 'You are now OFFLINE'),
        backgroundColor: _isOnline ? const Color(0xFF00E676) : Colors.redAccent,
      ),
    );
  }

  void _acceptOrder(int deliveryId) async {
    try {
      await ApiService.acceptDelivery(deliveryId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order accepted! Navigation enabled.')),
      );
      _loadDeliveries();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}')),
      );
    }
  }

  void _completeOrder(int deliveryId) async {
    try {
      await ApiService.completeDelivery(deliveryId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery marked as completed! Earnings updated.')),
      );
      _loadDeliveries();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dispatch & Earnings'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00E676)),
            onPressed: _isOnline ? () => _loadDeliveries() : null,
            tooltip: 'Refresh Feed',
          )
        ],
      ),
      body: Column(
        children: [
          // ONLINE / OFFLINE AVAILABILITY TOGGLE BAR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF1E1E1E),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 12,
                      color: _isOnline ? const Color(0xFF00E676) : Colors.redAccent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isOnline ? 'ONLINE (Receiving Orders)' : 'OFFLINE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isOnline ? const Color(0xFF00E676) : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _isOnline,
                  activeColor: const Color(0xFF00E676),
                  onChanged: _toggleOnlineStatus,
                ),
              ],
            ),
          ),

          // MAIN CONTENT AREA
          Expanded(
            child: !_isOnline
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.nightlight_round, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'You are currently Offline',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Switch online to start receiving Tukutuku cargo dispatches.',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E676),
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () => _toggleOnlineStatus(true),
                          child: const Text('Go Online', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  )
                : FutureBuilder<List<Delivery>>(
                    future: _futureDeliveries,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)));
                      } else if (snapshot.hasError && !snapshot.hasData) {
                        return Center(child: Text('Error loading feed: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text(
                            'No cargo delivery requests found.',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        );
                      }

                      final deliveries = snapshot.data!;
                      final completedOrders = deliveries.where((d) => d.status == 'completed');
                      final totalEarnings = completedOrders.fold<double>(0.0, (sum, item) => sum + item.fareUgx);
                      final completedCount = completedOrders.length;

                      return Column(
                        children: [
                          // EARNINGS SUMMARY BANNER
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.all(12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E1E1E), Color(0xFF2C2C2C)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('TOTAL EARNINGS', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(
                                      'UGX ${totalEarnings.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF00E676)),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('TRIPS COMPLETED', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$completedCount Delivered',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // DISPATCH FEED LIST VIEW
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: deliveries.length,
                              itemBuilder: (context, index) {
                                final delivery = deliveries[index];
                                final isPending = delivery.status == 'pending';
                                final isAccepted = delivery.status == 'accepted';

                                return Card(
                                  color: const Color(0xFF1E1E1E),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Order #${delivery.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            Chip(
                                              label: Text(delivery.status.toUpperCase(), style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                                              backgroundColor: isPending 
                                                  ? Colors.orangeAccent 
                                                  : isAccepted 
                                                      ? const Color(0xFF00E676) 
                                                      : Colors.grey,
                                            ),
                                          ],
                                        ),
                                        const Divider(color: Colors.grey),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.my_location, color: Color(0xFF00E676), size: 18),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text('Pickup: ${delivery.pickupLocation}', style: const TextStyle(fontSize: 14))),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on, color: Colors.redAccent, size: 18),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text('Drop-off: ${delivery.dropoffLocation}', style: const TextStyle(fontSize: 14))),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text('Cargo: ${delivery.cargoType}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                        const SizedBox(height: 14),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'UGX ${delivery.fareUgx.toStringAsFixed(0)}',
                                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00E676)),
                                            ),
                                            if (isPending)
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF00E676),
                                                  foregroundColor: Colors.black,
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                                onPressed: () => _acceptOrder(delivery.id),
                                                child: const Text('Accept Order', style: TextStyle(fontWeight: FontWeight.bold)),
                                              )
                                            else if (isAccepted)
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.navigation, color: Color(0xFF2979FF)),
                                                    onPressed: () => NavigationService.launchNavigation(destinationAddress: delivery.dropoffLocation),
                                                    tooltip: 'Navigate',
                                                  ),
                                                  const SizedBox(width: 6),
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.purpleAccent,
                                                      foregroundColor: Colors.white,
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                    ),
                                                    onPressed: () => _completeOrder(delivery.id),
                                                    child: const Text('Complete', style: TextStyle(fontWeight: FontWeight.bold)),
                                                  ),
                                                ],
                                              )
                                            else
                                              const Text(
                                                'Completed',
                                                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}