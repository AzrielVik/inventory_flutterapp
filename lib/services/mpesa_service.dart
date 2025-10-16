import 'dart:convert';
import 'package:http/http.dart' as http;

class MpesaService {
  final String baseUrl;

  MpesaService({required this.baseUrl});

  Future<Map<String, dynamic>> promptPayment({
    required double amount,
    required String phoneNumber,
    String reference = "SalePayment",
  }) async {
    final url = Uri.parse('$baseUrl/api/prompt-mpesa');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': amount,
        'mpesaNumber': phoneNumber,
        'reference': reference,
      }),
    );

    // Handle response
    if (response.statusCode == 200) {
      try {
        final res = jsonDecode(response.body) as Map<String, dynamic>;

        // Ensure CheckoutRequestID exists
        if (!res.containsKey("CheckoutRequestID")) {
          throw Exception(
              "Prompt request succeeded but no CheckoutRequestID found. Response: $res");
        }

        return res;
      } catch (e) {
        throw Exception('Failed to parse M-Pesa response: $e');
      }
    } else if (response.statusCode == 400) {
      throw Exception('Bad request: ${response.body}');
    } else if (response.statusCode == 404) {
      throw Exception('Endpoint not found (404): ${response.body}');
    } else {
      throw Exception(
          'M-Pesa request failed [${response.statusCode}]: ${response.body}');
    }
  }
}
