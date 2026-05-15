import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// ⚠️ IMPORTANT: Change this based on your setup
class ApiService {
  static const String baseUrl = 'https://giftsphere.riyan.org';
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String bankInfoPrefix = 'bank_info_';
  static const String lastPhoneKey = 'last_phone_number';
  
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
  static String _normalizePhone(String phone) {
  String value = phone.trim();

  if (value.startsWith('+966')) {
    value = value.substring(4);
  }

  if (value.startsWith('966')) {
    value = value.substring(3);
  }

  if (value.startsWith('0')) {
    value = value.substring(1);
  }

  return value;
}

static Future<void> _saveLastPhoneForStorage(String phone) async {
  final prefs = await SharedPreferences.getInstance();
  final normalizedPhone = _normalizePhone(phone);

  if (normalizedPhone.isNotEmpty) {
    await prefs.setString(lastPhoneKey, normalizedPhone);
  }
}

static Future<String> _getCurrentPhoneForStorage() async {
  final prefs = await SharedPreferences.getInstance();
  final userData = await getUserData();

  final phone = userData?['phone_number']?.toString() ??
      userData?['phone']?.toString() ??
      prefs.getString(lastPhoneKey) ??
      '';

  return _normalizePhone(phone);
}

static Future<void> saveLocalBankingInfo({
  required String bankName,
  required String iban,
  required String accountHolderName,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final phone = await _getCurrentPhoneForStorage();

  if (phone.isEmpty) return;

  await prefs.setString(
    '$bankInfoPrefix$phone',
    jsonEncode({
      'bank_name': bankName.trim(),
      'iban': iban.trim().toUpperCase(),
      'account_holder_name': accountHolderName.trim(),
    }),
  );
}

static Future<Map<String, dynamic>> getLocalBankingInfo() async {
  final prefs = await SharedPreferences.getInstance();
  final phone = await _getCurrentPhoneForStorage();

  if (phone.isEmpty) return {};

  final saved = prefs.getString('$bankInfoPrefix$phone');

  if (saved == null || saved.isEmpty) return {};

  try {
    return Map<String, dynamic>.from(jsonDecode(saved));
  } catch (_) {
    return {};
  }
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
  static Future<Map<String, dynamic>> requestOTP(String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/login/request/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message'], 'debug_otp': data['debug_otp']};
      } else {
        // 🚨 حماية من رد السيرفر كـ HTML
        if (response.body.startsWith('<!DOCTYPE html>') || response.statusCode >= 500) {
          print("🔴 السيرفر كراش (Backend Error)! كود الخطأ: ${response.statusCode}");
          return {'success': false, 'message': 'مشكلة في السيرفر (Backend Error ${response.statusCode})'};
        }
        return {'success': false, 'message': jsonDecode(response.body)['error'] ?? 'Failed'};
      }
    } catch (e) {
      print("🔴 الخطأ الحقيقي أثناء طلب الـ OTP هو: $e"); 
      return {'success': false, 'message': 'Network error'};
    }
  }
  
  /// Verify OTP
  static Future<Map<String, dynamic>> verifyOTP(String phone, String otp) async {
  try {
    final normalizedPhone = _normalizePhone(phone);

    final response = await http.post(
      Uri.parse('$baseUrl/api/login/verify/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': normalizedPhone,
        'otp': otp,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];

      await saveToken(token);
      await _saveLastPhoneForStorage(normalizedPhone);

      final existingUserData = await getUserData() ?? {};

      await saveUserData({
        ...existingUserData,
        'phone': normalizedPhone,
        'phone_number': normalizedPhone,
        'token': token,
      });

      await getCurrentUserProfile();

      return {'success': true, 'token': token};
    } else {
      return {'success': false, 'message': 'Invalid OTP'};
    }
  } catch (e) {
    return {'success': false, 'message': 'Network error'};
  }
}

  /// Get Products with Advanced Filters
  static Future<Map<String, dynamic>> getProducts({
    String? search,
    String? category,
    String? occasion,
    String? targetGender,
    String? recipientAge,
    String? budgetMin,
    String? budgetMax,
    String? interests,
  }) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'Not authenticated.'};

      List<String> queryParams = [];
      if (search != null && search.isNotEmpty) queryParams.add('search=$search');
      if (category != null && category.isNotEmpty) queryParams.add('category=$category');
      if (occasion != null && occasion.isNotEmpty) queryParams.add('occasion=$occasion');
      if (targetGender != null && targetGender.isNotEmpty) queryParams.add('target_gender=$targetGender');
      if (recipientAge != null && recipientAge.isNotEmpty) queryParams.add('recipient_age=$recipientAge');
      if (budgetMin != null && budgetMin.isNotEmpty) queryParams.add('budget_min=$budgetMin');
      if (budgetMax != null && budgetMax.isNotEmpty) queryParams.add('budget_max=$budgetMax');
      if (interests != null && interests.isNotEmpty) queryParams.add('interests=$interests');

      String queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/products/$queryString'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> products = (data is Map && data.containsKey('results')) ? data['results'] : data;
        return {'success': true, 'products': products};
      } else {
        return {'success': false, 'message': 'Failed to fetch products'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  // ==========================================
  // 🌟 WISHLIST API 🌟
  // ==========================================

  static Future<Map<String, dynamic>> getWishlists() async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'Not authenticated.'};
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/wishlist/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': 'Failed to fetch wishlist'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>> createWishlist(String title) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/wishlist/create/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
        body: jsonEncode({'title': title}),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Failed to create wishlist'};
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>> addToWishlist(int productId, int wishlistId) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/wishlist/add_product/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
        body: jsonEncode({'product_id': productId, 'wishlist_id': wishlistId}),
      );
      if (response.statusCode == 201 || response.statusCode == 200) return {'success': true};
      return {'success': false, 'message': 'Failed to add to wishlist'};
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>> removeFromWishlist(int productId, int wishlistId) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/wishlist/remove_product/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
        body: jsonEncode({'product_id': productId, 'wishlist_id': wishlistId}),
      );
      if (response.statusCode == 200) return {'success': true};
      return {'success': false, 'message': 'Failed to remove from wishlist'};
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  // ==========================================
  // 🛒 CART (LOCAL STORAGE) 🌟
  // ==========================================
  static const String cartKey = 'local_user_cart';

  static Future<void> addToCart(Map<String, dynamic> product) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> cartStrings = prefs.getStringList(cartKey) ?? [];
    List<Map<String, dynamic>> cartList = cartStrings.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

    int existingIndex = cartList.indexWhere((p) => p['id'] == product['id']);
    if (existingIndex >= 0) {
      cartList[existingIndex]['quantity'] = (cartList[existingIndex]['quantity'] ?? 1) + 1;
    } else {
      Map<String, dynamic> newProduct = Map.from(product);
      newProduct['quantity'] = 1;
      cartList.add(newProduct);
    }
    await prefs.setStringList(cartKey, cartList.map((e) => jsonEncode(e)).toList());
  }

  static Future<List<Map<String, dynamic>>> getCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> cartStrings = prefs.getStringList(cartKey) ?? [];
    return cartStrings.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  static Future<void> updateCartQuantity(int productId, int quantity) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> cartStrings = prefs.getStringList(cartKey) ?? [];
    List<Map<String, dynamic>> cartList = cartStrings.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

    int existingIndex = cartList.indexWhere((p) => p['id'] == productId);
    if (existingIndex >= 0) {
      cartList[existingIndex]['quantity'] = quantity;
      await prefs.setStringList(cartKey, cartList.map((e) => jsonEncode(e)).toList());
    }
  }

  static Future<void> removeFromCart(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> cartStrings = prefs.getStringList(cartKey) ?? [];
    List<Map<String, dynamic>> cartList = cartStrings.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

    cartList.removeWhere((p) => p['id'] == productId);
    await prefs.setStringList(cartKey, cartList.map((e) => jsonEncode(e)).toList());
  }

  static Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(cartKey);
  }

  // ==========================================
  // 🎁 EXCHANGES & OTHER APIs
  // ==========================================
  static Future<Map<String, dynamic>> createExchange(String title, double budget, List<int> participants) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'Not authenticated'};

      final response = await http.post(
        Uri.parse('$baseUrl/api/exchange/create/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
        body: jsonEncode({'title': title, 'budget': budget, 'participants': participants}),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200 || response.statusCode == 201) return {'success': true, 'data': jsonDecode(response.body)};
      return {'success': false, 'message': 'Failed to create event'};
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>> getMyAssignment(int exchangeId) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'Not authenticated'};
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/exchange/$exchangeId/my/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
      );
      if (response.statusCode == 200) return {'success': true, 'data': jsonDecode(response.body)};
      return {'success': false, 'message': 'Assignment not found'};
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

static Future<Map<String, dynamic>> joinExchange(String inviteCode) async {
  try {
    final token = await getToken();

    if (token == null) {
      return {'success': false, 'message': 'Not authenticated.'};
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/exchange/join/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: jsonEncode({
        'invite_code': inviteCode,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {
        'success': true,
        'data': jsonDecode(response.body),
      };
    }

    final decoded = jsonDecode(response.body);

    return {
      'success': false,
      'message': decoded['error'] ?? 'Failed to join the event.',
    };
  } catch (e) {
    return {'success': false, 'message': 'Network error'};
  }
}

  static Future<Map<String, dynamic>> getExchangeDetails(int exchangeId) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/exchange/$exchangeId/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
      );
      if (response.statusCode == 200) return {'success': true, 'data': jsonDecode(response.body)};
      return {'success': false, 'message': 'Failed to load details'};
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>> drawAssignments(int exchangeId) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/exchange/$exchangeId/draw/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
      );
      if (response.statusCode == 200) return {'success': true};
      return {'success': false, 'message': jsonDecode(response.body)['error'] ?? 'Failed to draw'};
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

static Future<Map<String, dynamic>> getMyExchanges() async {
  try {
    final token = await getToken();

    if (token == null) {
      return {'success': false, 'message': 'Not authenticated'};
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/exchange/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      return {
        'success': true,
        'data': jsonDecode(response.body),
      };
    }

    return {'success': false, 'message': 'Failed to fetch events'};
  } catch (e) {
    return {'success': false, 'message': 'Network error'};
  }
}

  static Future<Map<String, dynamic>> acceptExchangeInvite(int exchangeId) async {
    final token = await getToken();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/exchange/$exchangeId/accept/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
      );
      if (response.statusCode == 200) return {'success': true, 'data': jsonDecode(response.body)};
      return {'success': false, 'message': 'Failed to accept invitation'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> rejectExchangeInvite(int exchangeId) async {
    final token = await getToken();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/exchange/$exchangeId/reject/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
      );
      if (response.statusCode == 200) return {'success': true, 'data': jsonDecode(response.body)};
      return {'success': false, 'message': 'Failed to reject invitation'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateUserName(
    String firstName,
    String lastName,
  ) async {
    try {
      final token = await getToken();

      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final cleanFirstName = firstName.trim();
      final cleanLastName = lastName.trim();

      final existingUserData = await getUserData() ?? {};

      final locallyUpdatedData = {
        ...existingUserData,
        'first_name': cleanFirstName,
        'last_name': cleanLastName,
        'token': token,
      };

      await saveUserData(locallyUpdatedData);

      try {
        final response = await http.post(
          Uri.parse('$baseUrl/api/setname/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token',
          },
          body: jsonEncode({
            'first_name': cleanFirstName,
            'last_name': cleanLastName,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          try {
            final decoded = jsonDecode(response.body);
            final user = decoded['user'];

            if (user is Map<String, dynamic>) {
              final serverMergedData = {
                ...locallyUpdatedData,
                'first_name': user['first_name']?.toString() ?? cleanFirstName,
                'last_name': user['last_name']?.toString() ?? cleanLastName,
                'phone': user['phone_number']?.toString() ??
                    locallyUpdatedData['phone']?.toString() ??
                    '',
                'phone_number': user['phone_number']?.toString() ??
                    locallyUpdatedData['phone_number']?.toString() ??
                    '',
                'avatar': user['avatar']?.toString() ??
                    locallyUpdatedData['avatar']?.toString() ??
                    '',
                'bank_name': user['bank_name']?.toString() ??
                    locallyUpdatedData['bank_name']?.toString() ??
                    '',
                'iban': user['iban']?.toString() ??
                    locallyUpdatedData['iban']?.toString() ??
                    '',
                'account_holder_name': user['account_holder_name']?.toString() ??
                    locallyUpdatedData['account_holder_name']?.toString() ??
                    '',
                'token': token,
              };

              await saveUserData(serverMergedData);

              return {
                'success': true,
                'data': serverMergedData,
              };
            }
          } catch (_) {}

          return {
            'success': true,
            'data': locallyUpdatedData,
          };
        }

        return {
          'success': true,
          'data': locallyUpdatedData,
          'message': 'Saved locally',
        };
      } catch (_) {
        return {
          'success': true,
          'data': locallyUpdatedData,
          'message': 'Saved locally',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update name',
      };
    }
  }

  static Future<Map<String, dynamic>> updateBankingInfo({
  required String bankName,
  required String iban,
  required String accountHolderName,
}) async {
  try {
    final token = await getToken();

    if (token == null) {
      return {'success': false, 'message': 'Not authenticated'};
    }

    final cleanBankName = bankName.trim();
    final cleanIban = iban.trim().toUpperCase();
    final cleanHolder = accountHolderName.trim();

    await saveLocalBankingInfo(
      bankName: cleanBankName,
      iban: cleanIban,
      accountHolderName: cleanHolder,
    );

    final existingUserData = await getUserData() ?? {};

    final locallyUpdatedData = {
      ...existingUserData,
      'bank_name': cleanBankName,
      'iban': cleanIban,
      'account_holder_name': cleanHolder,
      'token': token,
    };

    await saveUserData(locallyUpdatedData);

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/update_profile/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'bank_name': cleanBankName,
          'iban': cleanIban,
          'account_holder_name': cleanHolder,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': locallyUpdatedData,
        };
      }

      return {
        'success': true,
        'data': locallyUpdatedData,
        'message': 'Saved locally',
      };
    } catch (_) {
      return {
        'success': true,
        'data': locallyUpdatedData,
        'message': 'Saved locally',
      };
    }
  } catch (e) {
    return {
      'success': false,
      'message': 'Failed to save banking information',
    };
  }
}
static Future<Map<String, dynamic>> getCurrentUserProfile() async {
  try {
    final token = await getToken();

    if (token == null) {
      return {'success': false, 'message': 'Not authenticated'};
    }

    final existingUserData = await getUserData() ?? {};
    final localBankInfo = await getLocalBankingInfo();

    final response = await http.get(
      Uri.parse('$baseUrl/api/profile/me/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final phoneFromServer = data['phone_number']?.toString() ?? '';
      final phoneFromLocal = existingUserData['phone']?.toString() ??
          existingUserData['phone_number']?.toString() ??
          '';

      final bankNameFromServer = data['bank_name']?.toString() ?? '';
      final ibanFromServer = data['iban']?.toString() ?? '';
      final holderFromServer =
          data['account_holder_name']?.toString() ?? '';

      final mergedData = {
        ...existingUserData,

        'id': data['id'],

        'first_name': data['first_name']?.toString() ??
            existingUserData['first_name']?.toString() ??
            '',

        'last_name': data['last_name']?.toString() ??
            existingUserData['last_name']?.toString() ??
            '',

        'phone': phoneFromServer.trim().isNotEmpty
            ? _normalizePhone(phoneFromServer)
            : _normalizePhone(phoneFromLocal),

        'phone_number': phoneFromServer.trim().isNotEmpty
            ? _normalizePhone(phoneFromServer)
            : _normalizePhone(phoneFromLocal),

        'avatar': data['avatar']?.toString() ??
            existingUserData['avatar']?.toString() ??
            '',

        'bank_name': bankNameFromServer.trim().isNotEmpty
            ? bankNameFromServer
            : localBankInfo['bank_name']?.toString() ??
                existingUserData['bank_name']?.toString() ??
                '',

        'iban': ibanFromServer.trim().isNotEmpty
            ? ibanFromServer
            : localBankInfo['iban']?.toString() ??
                existingUserData['iban']?.toString() ??
                '',

        'account_holder_name': holderFromServer.trim().isNotEmpty
            ? holderFromServer
            : localBankInfo['account_holder_name']?.toString() ??
                existingUserData['account_holder_name']?.toString() ??
                '',

        'token': token,
      };

      await saveUserData(mergedData);

      return {
        'success': true,
        'data': mergedData,
      };
    }

    final fallbackData = {
      ...existingUserData,
      'bank_name': localBankInfo['bank_name']?.toString() ??
          existingUserData['bank_name']?.toString() ??
          '',
      'iban': localBankInfo['iban']?.toString() ??
          existingUserData['iban']?.toString() ??
          '',
      'account_holder_name':
          localBankInfo['account_holder_name']?.toString() ??
              existingUserData['account_holder_name']?.toString() ??
              '',
      'token': token,
    };

    await saveUserData(fallbackData);

    return {
      'success': true,
      'data': fallbackData,
    };
  } catch (e) {
    final existingUserData = await getUserData() ?? {};
    final localBankInfo = await getLocalBankingInfo();

    final fallbackData = {
      ...existingUserData,
      'bank_name': localBankInfo['bank_name']?.toString() ??
          existingUserData['bank_name']?.toString() ??
          '',
      'iban': localBankInfo['iban']?.toString() ??
          existingUserData['iban']?.toString() ??
          '',
      'account_holder_name':
          localBankInfo['account_holder_name']?.toString() ??
              existingUserData['account_holder_name']?.toString() ??
              '',
    };

    await saveUserData(fallbackData);

    return {
      'success': true,
      'data': fallbackData,
    };
  }
}
static Future<Map<String, dynamic>> getMyPledges() async {
  try {
    final token = await getToken();

    if (token == null) {
      return {'success': false, 'message': 'Not authenticated'};
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/qattah/my-pledges/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return {
        'success': true,
        'data': jsonDecode(response.body),
      };
    }

    return {'success': false, 'message': 'Failed to fetch contributions'};
  } catch (e) {
    return {'success': false, 'message': 'Network error'};
  }
}
  
  static Future<void> logout() async {
    await removeToken();
  }

  // ==========================================
  // 🌟 نظام القطة (Qattah - Group Gift) 🌟
  // ==========================================

  static Future<Map<String, dynamic>> createQattah(
    String title,
    int productId, {
    String paymentMethodNote = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/qattah/create/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'title': title,
          'product_id': productId,
          'payment_method_note': paymentMethodNote,
        }),
      );

      if (response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final decoded = jsonDecode(response.body);
        return {
          'success': false,
          'message': decoded['error'] ?? 'Failed to create Qattah',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getQattahs({bool mine = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    String url = '$baseUrl/api/qattah/';
    if (mine) url += '?mine=true';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': 'Failed to fetch Qattahs: ${response.body}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> joinQattah(String inviteCode) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/qattah/join/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'invite_code': inviteCode,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final decoded = jsonDecode(response.body);
        return {'success': false, 'message': decoded['error'] ?? 'Failed to join'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> makePledge(int qattahId, double amount, {String message = ''}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/qattah/$qattahId/pledge/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'amount': amount.toString(),
          'message': message,
        }),
      );

      if (response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final decoded = jsonDecode(response.body);
        return {'success': false, 'message': decoded['error'] ?? 'Failed to pledge'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getQattahDetail(int qattahId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/qattah/$qattahId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': 'Failed to fetch details'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> acceptQattahInvite(int qattahId) async {
    final token = await getToken();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/qattah/$qattahId/accept/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
      );
      if (response.statusCode == 200) return {'success': true, 'data': jsonDecode(response.body)};
      return {'success': false, 'message': 'Failed to accept invitation'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> rejectQattahInvite(int qattahId) async {
    final token = await getToken();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/qattah/$qattahId/reject/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
      );
      if (response.statusCode == 200) return {'success': true, 'data': jsonDecode(response.body)};
      return {'success': false, 'message': 'Failed to reject invitation'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ==========================================
  // 🔔 نظام الإشعارات (Notifications)
  // ==========================================

  static Future<Map<String, dynamic>> getNotifications() async {
    final token = await getToken();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Failed to fetch notifications'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> markNotificationAsRead(int notificationId) async {
    final token = await getToken();
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/notifications/$notificationId/read/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
      );
      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'message': 'Failed to mark as read'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ==========================================
  // ⏰ نظام التذكيرات (Event Reminders)
  // ==========================================

  static Future<Map<String, dynamic>> getReminders() async {
    final token = await getToken();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/reminders/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
      );
      if (response.statusCode == 200) return {'success': true, 'data': jsonDecode(response.body)};
      return {'success': false, 'message': 'Failed to fetch reminders'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getUpcomingReminders() async {
    final token = await getToken();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/reminders/upcoming/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
      );
      if (response.statusCode == 200) return {'success': true, 'data': jsonDecode(response.body)};
      return {'success': false, 'message': 'Failed to fetch upcoming reminders'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> createReminder(Map<String, dynamic> reminderData) async {
    final token = await getToken();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/reminders/create/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
        body: jsonEncode(reminderData),
      );
      if (response.statusCode == 201) return {'success': true, 'data': jsonDecode(response.body)};
      return {'success': false, 'message': 'Failed to create reminder'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteReminder(int reminderId) async {
    final token = await getToken();
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/reminders/$reminderId/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
      );
      if (response.statusCode == 204) return {'success': true};
      return {'success': false, 'message': 'Failed to delete reminder'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> leaveExchange(int exchangeId) async {
    final token = await getToken();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/exchange/$exchangeId/leave/'),
        headers: {'Authorization': 'Token $token'},
      );
      if (response.statusCode == 200) return {'success': true};
      return {'success': false, 'message': 'Failed to leave event'};
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }
static Future<Map<String, dynamic>> leaveQattah(int qattahId) async {
  try {
    final token = await getToken();

    if (token == null) {
      return {
        'success': false,
        'message': 'Not authenticated',
      };
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/qattah/$qattahId/leave/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return {
        'success': true,
        'data': jsonDecode(response.body),
      };
    }

    final decoded = jsonDecode(response.body);

    return {
      'success': false,
      'message': decoded['error'] ?? 'Failed to leave Qattah',
    };
  } catch (e) {
    return {
      'success': false,
      'message': 'Network error',
    };
  }
}
  static Future<Map<String, dynamic>> takeGiftQuiz({
  required String occasion,
  required String recipientAge,
  required String recipientGender,
  required String interests,
  required String budgetMin,
  required String budgetMax,
}) async {  
  try {
    final token = await getToken();

    if (token == null) {
      return {
        'success': false,
        'message': 'Not authenticated.',
      };
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/products/quiz/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: jsonEncode({
        'occasion': occasion,
        'recipient_age': recipientAge,
        'recipient_gender': recipientGender,
        'interests': interests,
        'budget_min': budgetMin,
        'budget_max': budgetMax,
      }),
    ).timeout(const Duration(seconds: 10));

    final decoded = jsonDecode(response.body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return {
        'success': true,
        'attempt': decoded['attempt'],
        'products': decoded['recommended_products'] ?? [],
      };
    }

    return {
      'success': false,
      'message': decoded['error'] ?? 'Failed to get recommendations.',
    };
  } catch (e) {
    return {
      'success': false,
      'message': 'Network error',
    };
  }
}
}

class ContactService {
  static Future<void> sendInviteSMS(String phoneNumber, String inviteCode, String qattahTitle) async {
    final String message = "يا هلا! أدعوك للانضمام لقطة هدية ($qattahTitle) على تطبيق Giftsphere. استخدم الكود التالي للانضمام: $inviteCode";
    
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: <String, String>{
        'body': message,
      },
    );

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      print("Could not launch SMS app");
    }
  }
}