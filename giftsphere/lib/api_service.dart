import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ⚠️ IMPORTANT: Change this based on your setup
  // Android Emulator: http://10.0.2.2:8000
  // iOS Simulator: http://localhost:8000 or http://127.0.0.1:8000
  // Real Device: http://YOUR_PC_IP:8000 (e.g., http://192.168.1.100:8000)
  
static const String baseUrl = 'http://localhost:8000';
  // static const String baseUrl = 'http://localhost:8000'; // For iOS Simulator
  // static const String baseUrl = 'http://192.168.1.100:8000'; // For Real Device
  
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  
  /// Get stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }
  
  /// Save token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }
  
  /// Save user data
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userKey, jsonEncode(userData));
  }
  
  /// Get user data
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(userKey);
    if (userDataString != null) {
      return jsonDecode(userDataString);
    }
    return null;
  }
  
  /// Remove token and user data (logout)
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(userKey);
  }
  
  /// Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }
  
  /// Request OTP
  /// Sends OTP to the provided phone number
  static Future<Map<String, dynamic>> requestOTP(String phone) async {
    try {
      print('🔄 Requesting OTP for: $phone');
      print('📡 API URL: $baseUrl/api/login/request/');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/login/request/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phone': phone,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout. Please check if Django server is running.');
        },
      );
      
      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'OTP sent successfully',
          'debug_otp': data['debug_otp'], // Only present in DEBUG mode
        };
      } else if (response.statusCode == 429) {
        // Rate limit exceeded
        return {
          'success': false,
          'message': 'Too many requests. Please wait a moment and try again.',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Failed to send OTP',
        };
      }
    } catch (e) {
      print('❌ Error requesting OTP: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
  
  /// Verify OTP
  /// Verifies the OTP code and returns authentication token
  static Future<Map<String, dynamic>> verifyOTP(String phone, String otp) async {
    try {
      print('🔄 Verifying OTP for: $phone with code: $otp');
      print('📡 API URL: $baseUrl/api/login/verify/');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/login/verify/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phone': phone,
          'otp': otp,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout. Please check if Django server is running.');
        },
      );
      
      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        
        // Save token
        await saveToken(token);
        
        // Save user data if available
        final userData = {
          'phone': phone,
          'token': token,
        };
        await saveUserData(userData);
        
        return {
          'success': true,
          'token': token,
          'message': 'Login successful',
        };
      } else if (response.statusCode == 429) {
        // Rate limit exceeded
        return {
          'success': false,
          'message': 'Too many attempts. Please wait and try again.',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Invalid OTP',
        };
      }
    } catch (e) {
      print('❌ Error verifying OTP: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
  
  /// Get Products (Authenticated)
  static Future<Map<String, dynamic>> getProducts() async {
    try {
      final token = await getToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated. Please login.',
        };
      }
      
      print('🔄 Fetching products...');
      print('📡 API URL: $baseUrl/api/products/');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/products/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );
      
      print('📥 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final products = jsonDecode(response.body);
        print('✅ Fetched ${products.length} products');
        return {
          'success': true,
          'products': products,
        };
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await removeToken();
        return {
          'success': false,
          'message': 'Session expired. Please login again.',
          'requires_login': true,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch products',
        };
      }
    } catch (e) {
      print('❌ Error fetching products: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
  
  /// Get Wishlist (Authenticated)
  static Future<Map<String, dynamic>> getWishlist() async {
    try {
      final token = await getToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated. Please login.',
        };
      }
      
      print('🔄 Fetching wishlist...');
      print('📡 API URL: $baseUrl/api/wishlist');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/wishlist'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );
      
      print('📥 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final wishlist = jsonDecode(response.body);
        print('✅ Fetched wishlist');
        return {
          'success': true,
          'wishlist': wishlist,
        };
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await removeToken();
        return {
          'success': false,
          'message': 'Session expired. Please login again.',
          'requires_login': true,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch wishlist',
        };
      }
    } catch (e) {
      print('❌ Error fetching wishlist: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
  
  /// Logout
  static Future<void> logout() async {
    print('🔄 Logging out...');
    await removeToken();
    print('✅ Logged out successfully');
  }
}