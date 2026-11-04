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
      id: json['id'],
      pickupLocation: json['pickup_location'],
      dropoffLocation: json['dropoff_location'],
      cargoType: json['cargo_type'],
      fareUgx: double.parse(json['fare_ugx'].toString()),
      status: json['status'],
    );
  }
}