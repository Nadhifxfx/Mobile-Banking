import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Get stored JWT token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConstants.tokenKey);
  }

  // Save JWT token
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.tokenKey, token);
    await prefs.setBool(ApiConstants.isLoggedInKey, true);
  }

  // Save user data
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('customer_id', userData['id'] ?? 0);
    await prefs.setString('customer_name', userData['name'] ?? '');
    await prefs.setString('customer_username', userData['username'] ?? '');
    await prefs.setString('customer_email', userData['email'] ?? '');
    await prefs.setString('customer_phone', userData['phone'] ?? '');
    await prefs.setString('customer_cif', userData['cif_number'] ?? '');
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final customerId = prefs.getInt('customer_id');
    
    if (customerId == null) return null;
    
    return {
      'id': customerId,
      'name': prefs.getString('customer_name') ?? '',
      'username': prefs.getString('customer_username') ?? '',
      'email': prefs.getString('customer_email') ?? '',
      'phone': prefs.getString('customer_phone') ?? '',
      'cif_number': prefs.getString('customer_cif') ?? '',
    };
  }

  // Remove user data (logout)
  Future<void> removeUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('customer_id');
    await prefs.remove('customer_name');
    await prefs.remove('customer_username');
    await prefs.remove('customer_email');
    await prefs.remove('customer_phone');
    await prefs.remove('customer_cif');
  }

  // Remove token (logout)
  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConstants.tokenKey);
    await prefs.setBool(ApiConstants.isLoggedInKey, false);
    await removeUserData();
  }

  // Get headers with JWT token
  Future<Map<String, String>> getHeaders({bool needsAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (needsAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Login
  Future<Map<String, dynamic>> login(String username, String pin) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.middlewareBaseUrl}${ApiConstants.loginEndpoint}'),
        headers: await getHeaders(needsAuth: false),
        body: jsonEncode({
          'username': username,
          'pin': pin,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          await saveToken(data['token']);
        }
        // Save customer data
        if (data['customer'] != null) {
          await saveUserData(data['customer']);
        }
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // Register
  Future<Map<String, dynamic>> register({
    required String name,
    required String username,
    required String pin,
    required String email,
    required String phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.middlewareBaseUrl}${ApiConstants.registerEndpoint}'),
        headers: await getHeaders(needsAuth: false),
        body: jsonEncode({
          'customer_name': name,
          'customer_username': username,
          'customer_pin': pin,
          'customer_email': email,
          'customer_phone': phone,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        // Get detailed error message
        String errorMessage = 'Registration failed';
        if (error['message'] != null) {
          errorMessage = error['message'];
        } else if (error['error'] != null) {
          errorMessage = error['error'];
        } else if (error['details'] != null && error['details'] is List) {
          errorMessage = (error['details'] as List).map((e) => e['msg']).join(', ');
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Registration error: $e');
    }
  }

  // Get Balance (All Accounts)
  Future<Map<String, dynamic>> getBalance() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.middlewareBaseUrl}/account/balance'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch balance');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // Get Transaction History
  Future<List<dynamic>> getTransactions() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.middlewareBaseUrl}/transaction/history'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['transactions'] ?? [];
      } else {
        throw Exception('Failed to fetch transactions');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // Transfer Money
  Future<Map<String, dynamic>> transfer({
    required String fromAccount,
    required String toAccount,
    required double amount,
    String? description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.middlewareBaseUrl}/transaction/transfer'),
        headers: await getHeaders(),
        body: jsonEncode({
          'from_account': fromAccount,
          'to_account': toAccount,
          'amount': amount,
          'description': description ?? 'Transfer',
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Transfer failed');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // Withdraw Money
  Future<Map<String, dynamic>> withdraw({
    required String accountNumber,
    required double amount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.middlewareBaseUrl}/transaction/withdraw'),
        headers: await getHeaders(),
        body: jsonEncode({
          'account_number': accountNumber,
          'amount': amount,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Withdrawal failed');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // Deposit Money
  Future<Map<String, dynamic>> deposit({
    required String accountNumber,
    required double amount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.middlewareBaseUrl}/transaction/deposit'),
        headers: await getHeaders(),
        body: jsonEncode({
          'account_number': accountNumber,
          'amount': amount,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Deposit failed');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    await removeToken();
  }
}
