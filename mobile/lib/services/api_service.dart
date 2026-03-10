import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulator connecting to localhost backend
  // Use 127.0.0.1 for desktop builds
  // Use local network IP for physical devices (override via --dart-define)
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
  }

  static Future<void> _persistCurrentUserId(String userId) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString('current_user_id', userId);
  }

  static List<String> _candidateBaseUrls() {
    final hasCustomApiBase =
        physicalDeviceBaseUrl != _defaultPhysicalDeviceBaseUrl;

    final urls = <String>[];
    void addUrl(String url) {
      if (!urls.contains(url)) {
        urls.add(url);
      }
    }

    if (kIsWeb) {
      addUrl(physicalDeviceBaseUrl);
      if (!hasCustomApiBase) {
        addUrl(baseUrl);
      }
      return urls;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      addUrl(physicalDeviceBaseUrl);
      if (!hasCustomApiBase) {
        addUrl(emulatorBaseUrl);
        addUrl(baseUrl);
      }
      return urls;
    }

    addUrl(physicalDeviceBaseUrl);
    if (!hasCustomApiBase) {
      addUrl(baseUrl);
    }
    return urls;
  }

  static String _requireUserId() {
    if (_currentUserId.isEmpty) {
      throw Exception('No active user found. Complete onboarding first.');
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

  static Future<Map<String, dynamic>> getUserSummary() async {
    final userId = _requireUserId();
    final urls = _candidateBaseUrls()
        .map((url) => Uri.parse('$url/users/$userId/summary'))
        .toList();

    Object? lastError;

    for (final url in urls) {
      try {
        final response = await http
            .get(url)
            .timeout(const Duration(seconds: 60));

        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }

        lastError = Exception(
          'Failed to load summary (${response.statusCode}): ${response.body}',
        );
      } catch (error) {
        lastError = error;
      }
    }

    throw Exception('Unable to load summary. Last error: $lastError');
  }

  static Future<String> createUser() async {
    final urls = _candidateBaseUrls()
        .map((url) => Uri.parse('$url/users/'))
        .toList();

    Object? lastError;

    for (final url in urls) {
      try {
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'time_to_savings_goal_days': null}),
            )
            .timeout(const Duration(seconds: 60));

        if (response.statusCode == 201 || response.statusCode == 200) {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          final id = decoded['id'] as String?;
          if (id == null || id.isEmpty) {
            throw Exception('Backend did not return a valid user id');
          }
          _currentUserId = id;
          await _persistCurrentUserId(id);
          return id;
        }

        lastError = Exception(
          'Failed to create user (${response.statusCode}): ${response.body}',
        );
      } catch (error) {
        lastError = error;
      }
    }

    throw Exception(
      'Unable to reach backend. Start API and verify LAN host mapping (API_BASE_URL). Last error: $lastError',
    );
  }

  // --- Income API ---

  static Future<void> createIncome({
    required int amountCents,
    required String frequency,
    required String nextPaydate,
    required double confidenceScore,
  }) async {
    final userId = _requireUserId();
    final urls = _candidateBaseUrls()
        .map((url) => Uri.parse('$url/onboarding/$userId/income'))
        .toList();

    Object? lastError;
    for (final url in urls) {
      try {
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'amount_cents': amountCents,
                'frequency': frequency,
                'next_paydate': nextPaydate,
                'confidence_score': confidenceScore,
              }),
            )
            .timeout(const Duration(seconds: 60));

        if (response.statusCode == 201 || response.statusCode == 200) {
          return;
        }

        lastError = Exception(
          'Failed to save income (${response.statusCode}): ${response.body}',
        );
      } catch (error) {
        lastError = error;
      }
    }

    throw Exception('Unable to save income. Last error: $lastError');
  }

  // --- Expenses API ---

  static Future<void> createExpense({
    required String name,
    required int amountCents,
    required bool isFixed,
    required int? dueDateDay,
  }) async {
    final userId = _requireUserId();
    final urls = _candidateBaseUrls()
        .map((url) => Uri.parse('$url/onboarding/$userId/expenses'))
        .toList();

    Object? lastError;
    for (final url in urls) {
      try {
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'name': name,
                'amount_cents': amountCents,
                'is_fixed': isFixed,
                'due_date_day': dueDateDay,
              }),
            )
            .timeout(const Duration(seconds: 60));

        if (response.statusCode == 201 || response.statusCode == 200) {
          return;
        }

        lastError = Exception(
          'Failed to save expense (${response.statusCode}): ${response.body}',
        );
      } catch (error) {
        lastError = error;
      }
    }

    throw Exception('Unable to save expense. Last error: $lastError');
  }

  // --- Goals API ---

  static Future<void> createGoal({
    required String name,
    required int targetAmountCents,
    required int priorityWeight,
    String? imageUrl,
  }) async {
    final userId = _requireUserId();
    final urls = _candidateBaseUrls()
        .map((url) => Uri.parse('$url/onboarding/$userId/goal'))
        .toList();

    Object? lastError;
    for (final url in urls) {
      try {
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'name': name,
                'target_amount_cents': targetAmountCents,
                'priority': priorityWeight,
                'image_url': imageUrl,
              }),
            )
            .timeout(const Duration(seconds: 60));

        if (response.statusCode == 201 || response.statusCode == 200) {
          return;
        }

        lastError = Exception(
          'Failed to save goal (${response.statusCode}): ${response.body}',
        );
      } catch (error) {
        lastError = error;
      }
    }

    throw Exception('Unable to save goal. Last error: $lastError');
  }

  static Future<List<Map<String, dynamic>>> getGoals() async {
    final userId = _requireUserId();
    final urls = _candidateBaseUrls()
        .map((url) => Uri.parse('$url/onboarding/$userId/goals'))
        .toList();

    Object? lastError;
    for (final url in urls) {
      try {
        final response = await http
            .get(url)
            .timeout(const Duration(seconds: 60));
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body) as List<dynamic>;
          return decoded.cast<Map<String, dynamic>>();
        }
        lastError = Exception(
          'Failed to load goals (${response.statusCode}): ${response.body}',
        );
      } catch (error) {
        lastError = error;
      }
    }

    throw Exception('Unable to load goals. Last error: $lastError');
  }

  static Future<Map<String, dynamic>> getHabitsInsights() async {
    final userId = _requireUserId();
    final urls = _candidateBaseUrls()
        .map((url) => Uri.parse('$url/users/$userId/insights'))
        .toList();

    Object? lastError;
    for (final url in urls) {
      try {
        final response = await http
            .get(url)
            .timeout(const Duration(seconds: 60));
        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
        lastError = Exception(
          'Failed to load insights (${response.statusCode}): ${response.body}',
        );
      } catch (error) {
        lastError = error;
      }
    }

    throw Exception('Unable to load insights. Last error: $lastError');
  }

  static Future<Map<String, dynamic>> evaluatePurchase({
    required String itemName,
    required int priceCents,
    required String category,
    String? idempotencyKey,
  }) async {
    final userId = _requireUserId();
    final urls = _candidateBaseUrls()
        .map((url) => Uri.parse('$url/decisions/$userId/evaluate'))
        .toList();

    Object? lastError;
    for (final url in urls) {
      try {
        final response = await http
            .post(
              url,
              headers: _jsonHeaders(idempotencyKey: idempotencyKey),
              body: jsonEncode({
                'item_name': itemName,
                'price_cents': priceCents,
                'category': category,
              }),
            )
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 200 || response.statusCode == 201) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }

        lastError = Exception(
          'Failed to evaluate purchase (${response.statusCode}): ${response.body}',
        );
      } catch (error) {
        lastError = error;
      }
    }

    throw Exception('Unable to evaluate purchase. Last error: $lastError');
  }

  static Future<Map<String, dynamic>> getLatestEvaluatedPurchase() async {
    final userId = _requireUserId();
    final urls = _candidateBaseUrls()
        .map((url) => Uri.parse('$url/purchases/$userId/latest-evaluated'))
        .toList();

    Object? lastError;
    for (final url in urls) {
      try {
        final response = await http
            .get(url)
            .timeout(const Duration(seconds: 60));
        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
        lastError = Exception(
          'Failed to load latest purchase (${response.statusCode}): ${response.body}',
        );
      } catch (error) {
        lastError = error;
      }
    }

    throw Exception('Unable to load latest purchase. Last error: $lastError');
  }

  static Future<Map<String, dynamic>> updatePurchaseStatus({
    required String purchaseId,
    required String status,
    String? spentFromGoalId,
    String? idempotencyKey,
  }) async {
    final urls = _candidateBaseUrls()
        .map((url) => Uri.parse('$url/purchases/$purchaseId/status'))
        .toList();

    Object? lastError;
    for (final url in urls) {
      try {
        final response = await http
            .patch(
              url,
              headers: _jsonHeaders(idempotencyKey: idempotencyKey),
              body: jsonEncode({
                'status': status,
                'spent_from_goal_id': spentFromGoalId,
              }),
            )
            .timeout(const Duration(seconds: 60));

        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }

        lastError = Exception(
          'Failed to update purchase status (${response.statusCode}): ${response.body}',
        );
      } catch (error) {
        lastError = error;
      }
    }

    throw Exception('Unable to update purchase status. Last error: $lastError');
  }

  static Future<List<Map<String, dynamic>>> getPassedPurchases() async {
    final userId = _requireUserId();
    final urls = _candidateBaseUrls()
        .map(
          (url) => Uri.parse(
            '$url/purchases/$userId/history?status_filter=ABANDONED',
          ),
        )
        .toList();

    Object? lastError;
    for (final url in urls) {
      try {
        final response = await http
            .get(url)
            .timeout(const Duration(seconds: 60));

        if (response.statusCode == 200) {
          final List<dynamic> decoded = jsonDecode(response.body);
          return decoded.cast<Map<String, dynamic>>();
        }

        lastError = Exception(
          'Failed to load passed purchases (${response.statusCode}): ${response.body}',
        );
      } catch (error) {
        lastError = error;
      }
    }

    throw Exception('Unable to load passed purchases. Last error: $lastError');
  }

  static Future<Map<String, dynamic>> submitReflection({
    required String purchaseId,
    required int windowDays,
    required int regretScore,
    bool? feltFinancialPressure,
    double? actualDaysImpacted,
    String? idempotencyKey,
  }) async {
    final urls = _candidateBaseUrls()
        .map((url) => Uri.parse('$url/purchases/$purchaseId/reflect'))
        .toList();

    Object? lastError;
    for (final url in urls) {
      try {
        final response = await http
            .post(
              url,
              headers: _jsonHeaders(idempotencyKey: idempotencyKey),
              body: jsonEncode({
                'purchase_id': purchaseId,
                'window_days': windowDays,
                'regret_score': regretScore,
                'felt_financial_pressure': feltFinancialPressure,
                'actual_days_impacted': actualDaysImpacted,
              }),
            )
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 200 || response.statusCode == 201) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }

        lastError = Exception(
          'Failed to submit reflection (${response.statusCode}): ${response.body}',
        );
      } catch (error) {
        lastError = error;
      }
    }

    throw Exception('Unable to submit reflection. Last error: $lastError');
  }

  static Future<Map<String, dynamic>> getAiStatus() async {
    final urls = _candidateBaseUrls()
        .map((url) => Uri.parse('$url/health/ai'))
        .toList();

    Object? lastError;
    for (final url in urls) {
      try {
        final response = await http
            .get(url)
            .timeout(const Duration(seconds: 60));
        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
        lastError = Exception(
          'Failed to load AI status (${response.statusCode}): ${response.body}',
        );
      } catch (error) {
        lastError = error;
      }
    }

    throw Exception('Unable to read AI status. Last error: $lastError');
  }
}
