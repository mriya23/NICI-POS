import 'dart:convert';
import 'package:http/http.dart' as http;

class MidtransService {
  static const String _sandboxBaseUrl = 'https://api.sandbox.midtrans.com/v2';
  static const String _productionBaseUrl = 'https://api.midtrans.com/v2';

  final String serverKey;
  final bool isProduction;

  MidtransService({required this.serverKey, this.isProduction = false});

  String get _baseUrl => isProduction ? _productionBaseUrl : _sandboxBaseUrl;

  Map<String, String> get _headers {
    final basicAuth = 'Basic ${base64Encode(utf8.encode('$serverKey:'))}';
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': basicAuth,
    };
  }

  Future<Map<String, dynamic>> createQrisTransaction({
    required String orderId,
    required int amount,
  }) async {
    final url = Uri.parse('$_baseUrl/charge');
    final body = jsonEncode({
      'payment_type': 'qris',
      'transaction_details': {'order_id': orderId, 'gross_amount': amount},
      // 'qris': {'acquirer': 'gopay'}, // Optional, let Midtrans decide
    });

    try {
      final response = await http.post(url, headers: _headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Midtrans Error (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Connection Error: $e');
    }
  }

  Future<String> checkTransactionStatus(String orderId) async {
    final url = Uri.parse('$_baseUrl/$orderId/status');
    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['transaction_status'] as String? ?? 'unknown';
      } else if (response.statusCode == 404) {
        return 'not_found';
      } else {
        // throw Exception('Status check failed: ${response.statusCode}');
        return 'error';
      }
    } catch (e) {
      return 'error';
    }
  }

  Future<bool> cancelTransaction(String orderId) async {
    final url = Uri.parse('$_baseUrl/$orderId/cancel');
    try {
      final response = await http.post(url, headers: _headers);
      return response.statusCode == 200 ||
          response.statusCode ==
              409; // 409 usually means already cancelled/settled
    } catch (e) {
      return false;
    }
  }
}
