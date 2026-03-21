import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../lib/screens/decision_analysis_screen.dart';

void main() {
  group('DecisionAnalysisScreen Widget Tests', () {
    testWidgets('Displays Verdict and Primary Reason', (WidgetTester tester) async {
      final mockEvaluationData = {
        'id': 'test-123',
        'affordability_score': 95.0,
        'behavior_penalty': 0.0,
        'risk_level': 'Low Risk',
        'risk_breakdown': {
          'affordability': 0.0,
          'behavior': 0.0,
          'goal_impact': 0.0,
        }
      };

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: DecisionAnalysisScreen(evaluationData: mockEvaluationData),
          ),
        ),
      );

      // Verify strict UI cap is met (Verdict + Reason)
      expect(find.text('Safe to buy'), findsOneWidget);
      expect(find.text('This fits comfortably within your plan.'), findsOneWidget);
      
      // Verify behavior banner is missing (as expected for behavior_penalty = 0)
      expect(find.byIcon(Icons.psychology), findsNothing);

      // Verify the buttons exist and are correctly labeled for Safe to Buy
      expect(find.text('Buy item'), findsOneWidget);
      expect(find.text('Changed my mind'), findsOneWidget);
    });

    testWidgets('Displays Behavior Banner when penalty triggers', (WidgetTester tester) async {
      final mockEvaluationData = {
        'id': 'test-123',
        'affordability_score': 90.0,
        'behavior_penalty': 0.2, // > 0.15 triggers delay
        'risk_level': 'Moderate Risk',
        'risk_breakdown': {
          'behavior': 10.0,
          'goal_impact': 15.0, // Primary reason becomes Goal Impact
        }
      };

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: DecisionAnalysisScreen(evaluationData: mockEvaluationData),
          ),
        ),
      );

      // Verify Verdict and Primary Reason
      expect(find.text('Delay'), findsOneWidget);
      expect(find.text('This delays your goal significantly.'), findsOneWidget);
      
      // Verify behavior banner is present
      expect(find.byIcon(Icons.psychology), findsOneWidget);
      
      // Verify the buttons exist and are correctly labeled for Delay/Avoid
      expect(find.text('Accept recommendation'), findsOneWidget);
      expect(find.text('Proceed anyway'), findsOneWidget);
    });
  });
}
