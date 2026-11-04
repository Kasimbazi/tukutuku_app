import 'package:flutter/material.dart';
import '../models/delivery_model.dart';
import '../services/navigation_service.dart';

class OrderDetailsSheet extends StatelessWidget {
  final Delivery delivery;

  const OrderDetailsSheet({super.key, required this.delivery});

  @override
  Widget build(BuildContext context) {
    final isPending = delivery.status == 'pending';
    final isAccepted = delivery.status == 'accepted';
    final isCompleted = delivery.status == 'completed';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar for dragging
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order #${delivery.id} Details', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
          const Divider(color: Colors.grey, height: 24),
          
          // Route info
          Row(
            children: [
              const Icon(Icons.my_location, color: Color(0xFF00E676), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pickup Location', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(delivery.pickupLocation, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 9, top: 4, bottom: 4),
            child: Text('│', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Drop-off Destination', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(delivery.dropoffLocation, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Cargo & Fare Details Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cargo Type', style: TextStyle(color: Colors.grey, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(delivery.cargoType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Agreed Fare', style: TextStyle(color: Colors.grey, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text('UGX ${delivery.fareUgx.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action button
          if (!isCompleted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2979FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.map),
                label: const Text('Open Route in Google Maps', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(context);
                  NavigationService.launchNavigation(destinationAddress: delivery.dropoffLocation);
                },
              ),
            )
          else
            const Center(
              child: Text(
                'This delivery has been successfully completed.',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}