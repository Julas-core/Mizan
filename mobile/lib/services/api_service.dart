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
  static const String physicalDeviceBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.13:8000/api/v1',
  );
  static const String mockUserId = 'test-user-123';
  static String _currentUserId = mockUserId;
  static SharedPreferences? _prefs;

  static String get currentUserId => _currentUserId;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('current_user_id') ?? mockUserId;
  }

  static Future<void> _persistCurrentUserId(String userId) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString('current_user_id', userId);
  }

  static List<String> _candidateBaseUrls() {
    if (kIsWeb) {
      return [physicalDeviceBaseUrl, baseUrl];
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return [physicalDeviceBaseUrl, emulatorBaseUrl, baseUrl];
    }

    return [physicalDeviceBaseUrl, baseUrl];
  }

  static Future<Map<String, dynamic>> getUserSummary() async {
    final urls = _candidateBaseUrls()
        .map((url) => Uri.parse('$url/users/$currentUserId/summary'))
        .toList();

    Object? lastError;

    for (final url in urls) {
      try {
        final response = await http.get(url).timeout(const Duration(seconds: 6));

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

    debugPrint('Falling back to mock summary. Last error: $lastError');
    return {
      'safe_to_spend_cents': 0,
      'days_to_next_income': 0,
      'total_monthly_income_cents': 0,
      'total_monthly_fixed_expenses_cents': 0,
      'total_goals_priority_weight': 0,
    };
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
            .timeout(const Duration(seconds: 6));

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
    final urls = _candidateBaseUrls()
        .map((url) => Uri.parse('$url/onboarding/$currentUserId/income'))
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
            .timeout(const Duration(seconds: 6));

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
    final urls = _candidateBaseUrls()
        .map((url) => Uri.parse('$url/onboarding/$currentUserId/expenses'))
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
            .timeout(const Duration(seconds: 6));

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
    final urls = _candidateBaseUrls()
        .map((url) => Uri.parse('$url/onboarding/$currentUserId/goal'))
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
            .timeout(const Duration(seconds: 6));

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

  // --- Decision Analysis API (Mocked from before) ---

  static Future<Map<String, dynamic>> evaluatePurchase(
    String itemName,
    int priceCents,
    String category,
  ) async {
    final urls = _candidateBaseUrls()
        .map((url) => Uri.parse('$url/decisions/$currentUserId/evaluate'))
        .toList();

    Object? lastError;
    for (final url in urls) {
      try {
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
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

  static Future<Map<String, dynamic>> getAiStatus() async {
    final urls = _candidateBaseUrls().map((url) => Uri.parse('$url/health/ai')).toList();

    Object? lastError;
    for (final url in urls) {
      try {
        final response = await http.get(url).timeout(const Duration(seconds: 6));
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
