import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart'; 
import '../models/product.dart';
import '../models/sale.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.8.26:5000';

  // -------------------- PRODUCT ENDPOINTS --------------------

  static Future<List<Product>> getProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products'));
    if (response.statusCode == 200) {
      List jsonData = json.decode(response.body);
      return jsonData.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  static Future<Product> createProduct(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/products'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode == 201) {
      return Product.fromJson(json.decode(response.body));
    } else {
      throw Exception(
        json.decode(response.body)['error'] ?? 'Product creation failed',
      );
    }
  }

  static Future<bool> updateProduct(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/products/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    return response.statusCode == 200;
  }

  static Future<void> deleteProduct(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/products/$id'));
    if (response.statusCode != 200) {
      throw Exception(
        json.decode(response.body)['error'] ?? 'Failed to delete product',
      );
    }
  }

  // -------------------- SALE ENDPOINTS --------------------

  static Future<Sale> createSale(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sales'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    if (response.statusCode == 201) {
      return Sale.fromJson(json.decode(response.body));
    } else {
      throw Exception(
        json.decode(response.body)['error'] ?? 'Sale creation failed',
      );
    }
  }

  static Future<bool> addSale({
    required String productId,
    required String customerName,
    required double total,
    required String mpesaNumber,
    double? weightPerUnit,
    int? numUnits,
    String? checkoutId,
  }) async {
    try {
      final data = {
        'product_id': productId,
        'customer_name': customerName,
        'total_price': total,
        'mpesaNumber': mpesaNumber,
        if (weightPerUnit != null) 'weight_per_unit': weightPerUnit,
        if (numUnits != null) 'num_units': numUnits,
        if (checkoutId != null && checkoutId.isNotEmpty) 'checkoutId': checkoutId,
      };

      await createSale(data);
      return true;
    } catch (e) {
      debugPrint('Error adding sale: $e');
      return false;
    }
  }

  static Future<List<Sale>> fetchSales({String? date}) async {
    final uri = date != null
        ? Uri.parse('$baseUrl/sales?date=$date')
        : Uri.parse('$baseUrl/sales');

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      List jsonData = json.decode(response.body);
      return jsonData.map((e) => Sale.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load sales');
    }
  }

  static Future<List<Sale>> getSales() async {
    return await fetchSales();
  }

  static Future<Sale> fetchSaleById(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/sales/$id'));
    if (response.statusCode == 200) {
      return Sale.fromJson(json.decode(response.body));
    } else {
      throw Exception(
        json.decode(response.body)['error'] ?? 'Sale not found',
      );
    }
  }

  static Future<Sale> updateSale(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/sales/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      return Sale.fromJson(json.decode(response.body));
    } else {
      throw Exception(
        json.decode(response.body)['error'] ?? 'Sale update failed',
      );
    }
  }

  static Future<void> deleteSale(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/sales/$id'));
    if (response.statusCode != 200) {
      throw Exception(
        json.decode(response.body)['error'] ?? 'Failed to delete sale',
      );
    }
  }

  // -------------------- STOCK ENDPOINT --------------------

  static Future<Map<String, dynamic>> fetchStock() async {
    final response = await http.get(Uri.parse('$baseUrl/stock'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch stock');
    }
  }

  // -------------------- MPESA ENDPOINT --------------------

  static Future<Map<String, dynamic>> sendMpesaPrompt({
    required String phoneNumber,
    required double amount,
    String reference = "SalePayment",
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/prompt-mpesa'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "amount": amount,
          "mpesaNumber": phoneNumber,
          "reference": reference,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception("Prompt failed: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error sending M-Pesa prompt: $e");
    }
  }
}

// -------------------- APPWRITE AUTH --------------------

class AuthService {
  static const String endpoint = 'https://cloud.appwrite.io/v1';
  static const String projectId = '68be9c92000402fc5b6f';

  static final Client client = Client()
    ..setEndpoint(endpoint)
    ..setProject(projectId);

  static final Account account = Account(client);

  /// Signup with email/password
  static Future<User> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    return await account.create(
      userId: ID.unique(),
      email: email,
      password: password,
      name: name,
    );
  }

  /// Login (create session)
  static Future<Session> login({
    required String email,
    required String password,
  }) async {
    return await account.createEmailPasswordSession(
      email: email,
      password: password,
    );
  }

  /// Logout (delete current session)
  static Future<void> logout() async {
    try {
      await account.deleteSession(sessionId: 'current');
    } catch (_) {
      // ignore if already logged out
    }
  }

  /// Send forgot password email
  static Future<void> forgotPassword({
    required String email,
    required String redirectUrl,
  }) async {
    await account.createRecovery(email: email, url: redirectUrl);
  }

  /// Reset password after clicking email link
  static Future<void> resetPassword({
    required String userId,
    required String secret,
    required String newPassword,
  }) async {
    await account.updateRecovery(
      userId: userId,
      secret: secret,
      password: newPassword,
    );
  }

  /// Get logged in user (returns null if no valid session)
  static Future<User?> getUser() async {
    try {
      return await account.get();
    } on AppwriteException catch (e) {
      if (e.code == 401) {
        // Invalid / expired session → clear and return null
        await logout();
        return null;
      }
      rethrow;
    }
  }

  /// Update user name (Appwrite top-level field)
  static Future<User> updateUserName(String newName) async {
    try {
      return await account.updateName(name: newName);
    } on AppwriteException catch (e) {
      debugPrint("Error updating name: ${e.message}");
      rethrow;
    }
  }

  /// Update user preferences (company name, photo URL, etc.)
  static Future<User> updateUserPrefs(Map<String, dynamic> prefs) async {
    try {
      return await account.updatePrefs(prefs: prefs);
    } on AppwriteException catch (e) {
      debugPrint("Error updating prefs: ${e.message}");
      rethrow;
    }
  }
}
