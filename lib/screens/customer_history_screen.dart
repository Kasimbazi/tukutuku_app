import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/delivery_model.dart';
import '../services/navigation_service.dart';
import '../widgets/order_details_sheet.dart'; // <--- Import the modal widget

class CustomerHistoryScreen extends StatefulWidget {
  const CustomerHistoryScreen({super.key});

  @override
  State<CustomerHistoryScreen> createState() => _CustomerHistoryScreenState();
}

class _CustomerHistoryScreenState extends State<CustomerHistoryScreen> {
  late Future<List<Delivery>> _futureHistory;

  @override
    void initState() {
      super.initState();
      _loadHistory();
    }

    // 1. Create a dedicated async helper function
    Future<List<Delivery>> _fetchHistory() async {
      final response = await ApiService.getDeliveries();

      // Handle wrapped responses like {"data": [...]} or raw List [...]
      final List rawList = (response is Map && response.containsKey('data'))
          ? response['data']
          : (response is List ? response : []);

      return rawList.map((json) => Delivery.fromJson(json as Map<String, dynamic>)).toList();
    }

    void _loadHistory() {
      setState(() {
        _futureHistory = _fetchHistory();
      });
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cargo History'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00E676)),
            onPressed: _loadHistory,
            tooltip: 'Refresh History',
          ),
        ],
      ),
      body: FutureBuilder<List<Delivery>>(
        future: _futureHistory,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading history: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No delivery history found.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          final deliveries = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: deliveries.length,
            itemBuilder: (context, index) {
              final delivery = deliveries[index];
              final isPending = delivery.status == 'pending';
              final isAccepted = delivery.status == 'accepted';
              final isCompleted = delivery.status == 'completed';

              return Card(
                color: const Color(0xFF1E1E1E),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    // Opens the interactive bottom sheet when card is tapped
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (context) => OrderDetailsSheet(delivery: delivery),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Trip #${delivery.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Chip(
                              label: Text(delivery.status.toUpperCase(), style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                              backgroundColor: isPending 
                                  ? Colors.orangeAccent 
                                  : isAccepted 
                                      ? const Color(0xFF2979FF) 
                                      : const Color(0xFF00E676),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.grey),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.my_location, color: Color(0xFF00E676), size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text('From: ${delivery.pickupLocation}', style: const TextStyle(fontSize: 14))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.redAccent, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text('To: ${delivery.dropoffLocation}', style: const TextStyle(fontSize: 14))),
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
                            if (!isCompleted)
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF2979FF),
                                  side: const BorderSide(color: Color(0xFF2979FF)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.map, size: 16),
                                label: const Text('View Route'),
                                onPressed: () {
                                  NavigationService.launchNavigation(destinationAddress: delivery.dropoffLocation);
                                },
                              )
                            else
                              const Text(
                                'Delivered successfully',
                                style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}