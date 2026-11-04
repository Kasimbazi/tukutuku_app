import 'dart:convert';
import 'package:http/http.dart' as http;
import 'shared_prefs_helper.dart'; // Or wherever you store your Sanctum auth token

class ApiService {
  // Update with your PC's local IP address if running on a physical device
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  static Future<Map<String, dynamic>> createDelivery({
    required String pickup,
    required String dropoff,
    required String cargoType,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/deliveries'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'pickup_location': pickup,
        'dropoff_location': dropoff,
        'cargo_type': cargoType,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create delivery: ${response.body}');
    }
  }

  static Future<List<dynamic>> getDeliveries() async {
    final response = await http.get(Uri.parse('$baseUrl/deliveries'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load deliveries');
    }
  }

  static Future<Map<String, dynamic>> acceptDelivery(int deliveryId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/deliveries/$deliveryId/accept'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to accept delivery: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> completeDelivery(int deliveryId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/deliveries/$deliveryId/complete'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to complete delivery: ${response.body}');
    }
  }
}