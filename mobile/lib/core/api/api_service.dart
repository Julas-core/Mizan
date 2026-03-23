import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../errors/app_exception.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1';
  static const String emulatorBaseUrl = 'http://10.0.2.2:8000/api/v1';
  static const String _defaultPhysicalDeviceBaseUrl =
      'https://mizan-backend.onrender.com/api/v1';
  static const String physicalDeviceBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultPhysicalDeviceBaseUrl,
  );
  static String _currentUserId = '';
  static SharedPreferences? _prefs;

  static String get currentUserId => _currentUserId;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('current_user_id') ?? '';
    if (kDebugMode) {
      print('ApiService: Initialized with UserID: "$_currentUserId"');
    }
  }

  static Future<void> _persistCurrentUserId(String userId) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString('current_user_id', userId);
    if (kDebugMode) {
      print('ApiService: Persisted UserID: "$userId"');
    }
  }

  static List<String> _candidateBaseUrls() {
    final urls = <String>[];
    
    // 1. Prioritize Remote/Physical Target
    urls.add(physicalDeviceBaseUrl);

    // 2. Add Local Fallbacks ONLY in Debug Mode
    if (kDebugMode) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        urls.add(emulatorBaseUrl);
      }
      urls.add(baseUrl);
    }
    
    return urls.toSet().toList(); // Unique items only
  }

  static String _requireUserId() {
    if (_currentUserId.isEmpty) {
      if (kDebugMode) {
        print('ApiService: ERROR - _requireUserId called but _currentUserId is empty!');
      }
      throw const AuthException(
        'No active user found. Complete onboarding first.',
      );
    }
    return _currentUserId;
  }

  static Map<String, String> _jsonHeaders({String? idempotencyKey}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
      headers['Idempotency-Key'] = idempotencyKey;
    }
    return headers;
  }

  static Future<http.Response> _executeRequest(
    String method,
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final urls = _candidateBaseUrls()
        .map((url) => Uri.parse('$url$endpoint'))
        .toList();

    Object? lastError;
    for (final url in urls) {
      if (kDebugMode) {
        print('ApiService: Attempting $method $url');
      }
      try {
        http.Response response;
        if (method == 'GET') {
          response = await http.get(url, headers: headers).timeout(timeout);
        } else if (method == 'POST') {
          response = await http
              .post(url, headers: headers, body: body)
              .timeout(timeout);
        } else if (method == 'PATCH') {
          response = await http
              .patch(url, headers: headers, body: body)
              .timeout(timeout);
        } else {
          throw Exception('Unsupported HTTP method');
        }

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          throw ApiException(
            response.statusCode,
            'Auth error: ${response.statusCode}',
          );
        } else {
          throw ApiException(
            response.statusCode,
            'API returned error ${response.statusCode}: ${response.body}',
          );
        }
      } catch (e) {
        lastError = e;
        if (e is AppException) {
          rethrow; // Don't swallow AppExceptions, let them bubble up
        }
        if (e is SocketException || e is TimeoutException) {
          // allow fallback for network issues
        } else {
          rethrow;
        }
      }
    }

    if (lastError is SocketException || lastError is TimeoutException) {
      final msg = kDebugMode 
        ? 'Network error: $method ${urls.first}. Is the backend up at Render?' 
        : 'Network connection failed.';
      throw NetworkException(msg);
    }

    throw lastError is Exception ? lastError : const UnknownException();
  }

  static Future<Map<String, dynamic>> getUserSummary() async {
    final userId = _requireUserId();
    final response = await _executeRequest('GET', '/users/$userId/summary');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<String> createUser() async {
    final response = await _executeRequest(
      'POST',
      '/users/',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'time_to_savings_goal_days': null}),
    );
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final id = decoded['id'] as String?;
    if (id == null || id.isEmpty) {
      throw const UnknownException('Backend did not return a valid user id');
    }
    _currentUserId = id;
    await _persistCurrentUserId(id);
    return id;
  }

  static Future<void> createIncome({
    required int amountCents,
    required String frequency,
    required String nextPaydate,
    required double confidenceScore,
  }) async {
    final userId = _requireUserId();
    await _executeRequest(
      'POST',
      '/onboarding/$userId/income',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount_cents': amountCents,
        'frequency': frequency,
        'next_paydate': nextPaydate,
        'confidence_score': confidenceScore,
      }),
    );
  }

  static Future<void> createExpense({
    required String name,
    required int amountCents,
    required bool isFixed,
    required int? dueDateDay,
  }) async {
    final userId = _requireUserId();
    await _executeRequest(
      'POST',
      '/onboarding/$userId/expenses',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'amount_cents': amountCents,
        'is_fixed': isFixed,
        'due_date_day': dueDateDay,
      }),
    );
  }

  static Future<void> createGoal({
    required String name,
    required int targetAmountCents,
    required int priorityWeight,
    String? imageUrl,
  }) async {
    final userId = _requireUserId();
    await _executeRequest(
      'POST',
      '/onboarding/$userId/goal',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'target_amount_cents': targetAmountCents,
        'priority': priorityWeight,
        'image_url': imageUrl,
      }),
    );
  }

  static Future<List<Map<String, dynamic>>> getGoals() async {
    final userId = _requireUserId();
    final response = await _executeRequest('GET', '/onboarding/$userId/goals');
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> getHabitsInsights() async {
    final userId = _requireUserId();
    final response = await _executeRequest('GET', '/users/$userId/insights');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> evaluatePurchase({
    required String itemName,
    required int priceCents,
    required String category,
    String? idempotencyKey,
  }) async {
    final userId = _requireUserId();
    final response = await _executeRequest(
      'POST',
      '/decisions/$userId/evaluate',
      headers: _jsonHeaders(idempotencyKey: idempotencyKey),
      body: jsonEncode({
        'item_name': itemName,
        'price_cents': priceCents,
        'category': category,
      }),
      timeout: const Duration(seconds: 8),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getLatestEvaluatedPurchase() async {
    final userId = _requireUserId();
    final response = await _executeRequest(
      'GET',
      '/purchases/$userId/latest-evaluated',
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updatePurchaseStatus({
    required String purchaseId,
    required String status,
    String? spentFromGoalId,
    String? idempotencyKey,
  }) async {
    final response = await _executeRequest(
      'PATCH',
      '/purchases/$purchaseId/status',
      headers: _jsonHeaders(idempotencyKey: idempotencyKey),
      body: jsonEncode({
        'status': status,
        'spent_from_goal_id': spentFromGoalId,
      }),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> getPassedPurchases() async {
    final userId = _requireUserId();
    final response = await _executeRequest(
      'GET',
      '/purchases/$userId/history?status_filter=ABANDONED',
    );
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> submitReflection({
    required String purchaseId,
    required int windowDays,
    required int regretScore,
    bool? feltFinancialPressure,
    double? actualDaysImpacted,
    String? idempotencyKey,
  }) async {
    final response = await _executeRequest(
      'POST',
      '/purchases/$purchaseId/reflect',
      headers: _jsonHeaders(idempotencyKey: idempotencyKey),
      body: jsonEncode({
        'purchase_id': purchaseId,
        'window_days': windowDays,
        'regret_score': regretScore,
        'felt_financial_pressure': feltFinancialPressure,
        'actual_days_impacted': actualDaysImpacted,
      }),
      timeout: const Duration(seconds: 8),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getAiStatus() async {
    final response = await _executeRequest('GET', '/health/ai');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
