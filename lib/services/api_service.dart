import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/delivery_model.dart'; 

class ApiService {
  // Use 'http://10.0.2.2:8000/api' for Android Emulator or 'http://127.0.0.1:8000/api' for Chrome/Web
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  static const Duration _timeout = Duration(seconds: 15);

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json', // Forces Laravel to return JSON instead of HTML error pages
      };

  static Future<dynamic> createDelivery({
    required String pickup,
    required String dropoff,
    required String cargoType,
  }) async {
    final url = Uri.parse('$baseUrl/deliveries');
    debugPrint('POST Request -> $url');

    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'pickup_location': pickup,
          'dropoff_location': dropoff,
          'cargo_type': cargoType,
        }),
      ).timeout(_timeout);

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      return _processResponse(response);
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on http.ClientException {
      throw Exception('Network connection failed. Server might be offline.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred: $e');
    }
  }

  static Future<dynamic> getDeliveries() async {
    final url = Uri.parse('$baseUrl/deliveries');
    debugPrint('GET Request -> $url');

    try {
      final response = await http.get(
        url,
        headers: _headers,
      ).timeout(_timeout);

      debugPrint('Response Status: ${response.statusCode}');
      return _processResponse(response);
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on http.ClientException {
      throw Exception('Network connection failed. Server might be offline.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred: $e');
    }
  }

  static Future<dynamic> acceptDelivery(int deliveryId) async {
    final url = Uri.parse('$baseUrl/deliveries/$deliveryId/accept');
    debugPrint('POST Request -> $url');

    try {
      final response = await http.post(
        url,
        headers: _headers,
      ).timeout(_timeout);

      debugPrint('Response Status: ${response.statusCode}');
      return _processResponse(response);
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on http.ClientException {
      throw Exception('Network connection failed. Server might be offline.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred: $e');
    }
  }

  static Future<dynamic> completeDelivery(int deliveryId) async {
    final url = Uri.parse('$baseUrl/deliveries/$deliveryId/complete');
    debugPrint('POST Request -> $url');

    try {
      final response = await http.post(
        url,
        headers: _headers,
      ).timeout(_timeout);

      debugPrint('Response Status: ${response.statusCode}');
      return _processResponse(response);
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on http.ClientException {
      throw Exception('Network connection failed. Server might be offline.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Helper method to safely parse server responses and extract Laravel error messages
  static dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      try {
        return jsonDecode(response.body);
      } catch (_) {
        throw Exception('Invalid JSON response received from server.');
      }
    } else {
      String errorMessage = 'Server error (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey('message')) {
          errorMessage = decoded['message'];
        } else if (decoded is Map && decoded.containsKey('error')) {
          errorMessage = decoded['error'];
        }
      } catch (_) {
        // Fallback if body is not JSON (e.g. Laravel HTML crash page)
        errorMessage = response.body.isNotEmpty 
            ? response.body.substring(0, response.body.length > 100 ? 100 : response.body.length) 
            : 'Unknown error';
      }
      throw Exception(errorMessage);
    }
  }
}