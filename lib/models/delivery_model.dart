class Delivery {
  final int id;
  final String pickupLocation;
  final String dropoffLocation;
  final String cargoType;
  final double fareUgx;
  final String status;

  Delivery({
    required this.id,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.cargoType,
    required this.fareUgx,
    required this.status,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      // Safely parse ID even if backend sends it as a String or int
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      pickupLocation: json['pickup_location']?.toString() ?? 'Unknown Pickup',
      dropoffLocation: json['dropoff_location']?.toString() ?? 'Unknown Dropoff',
      cargoType: json['cargo_type']?.toString() ?? 'Standard Tukutuku',
      // Safely parse numbers regardless of whether they are int, double, or String
      fareUgx: double.tryParse(json['fare_ugx']?.toString() ?? '0') ?? 0.0,
      status: json['status']?.toString() ?? 'pending',
    );
  }
}