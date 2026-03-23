import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/utils/decision_translator.dart';

void main() {
  group('DecisionTranslator', () {
    test('Translates severe risk / deficit mode correctly', () {
      final input = {
        'deficit_mode': true,
        'behavior_penalty': 0.0,
        'affordability_score': 80.0,
      };

      final result = DecisionTranslator.translate(input);
      expect(result.verdict, 'Avoid');
      expect(
        result.primaryReason,
        'This will leave you short before your next income.',
      );
    });

    test(
      'High behavior penalty with moderate affordability results in Avoid',
      () {
        final input = {
          'behavior_penalty': 0.2, // > 0.15
          'affordability_score': 55.0, // < 60
          'risk_breakdown': {'behavior': 20.0, 'affordability': 5.0},
        };

        final result = DecisionTranslator.translate(input);
        expect(result.verdict, 'Avoid');
        expect(result.primaryReason, 'You tend to regret purchases like this.');
        expect(
          result.tinyStat,
          isNull,
        ); // Behavior doesn't have a tiny stat by design
      },
    );

    test('High behavior penalty with high affordability results in Delay', () {
      final input = {
        'behavior_penalty': 0.2, // > 0.15
        'affordability_score': 90.0, // > 60
        'risk_breakdown': {'behavior': 20.0, 'affordability': 2.0},
      };

      final result = DecisionTranslator.translate(input);
      expect(result.verdict, 'Delay');
      expect(result.primaryReason, 'You tend to regret purchases like this.');
    });

    test('Prioritizes Behavior > Affordability > Goal in tie-breaking', () {
      final input = {
        'affordability_score': 80.0,
        'risk_breakdown': {
          'behavior': 15.0,
          'affordability': 15.0,
          'goal_impact': 15.0,
        },
      };

      final result = DecisionTranslator.translate(input);
      expect(
        result.verdict,
        'Safe to buy',
      ); // Since behavior < 0.15 threshold theoretically, but risk exists
      expect(result.primaryReason, 'You tend to regret purchases like this.');
    });

    test('Displays correct tiny stat for goal delay', () {
      final input = {
        'affordability_score': 85.0,
        'risk_breakdown': {'goal_impact': 25.0},
        'goal_delay_days': {
          'uuid-123': {'delay_days': 12.5, 'relative_delay_pct': 5.0},
        },
      };

      final result = DecisionTranslator.translate(input);
      expect(result.primaryReason, 'This delays your goal significantly.');
      expect(result.tinyStat, '+13 days to goal');
    });

    test('Low risk maps to Safe to Buy', () {
      final input = {
        'affordability_score': 95.0,
        'risk_level': 'Low Risk',
        'risk_breakdown': {
          'affordability': 0.0,
          'behavior': 0.0,
          'goal_impact': 0.0,
        },
      };

      final result = DecisionTranslator.translate(input);
      expect(result.verdict, 'Safe to buy');
      expect(result.primaryReason, 'This fits comfortably within your plan.');
    });

    test('Includes dominant factor and recommended action metadata', () {
      final input = {
        'behavior_penalty': 0.2,
        'affordability_score': 55.0,
        'risk_breakdown': {
          'behavior': 18.0,
          'affordability': 4.0,
          'goal_impact': 2.0,
        },
      };

      final result = DecisionTranslator.translate(input);
      expect(result.dominantFactor, 'behavior');
      expect(result.recommendedAction, 'avoid');
    });

    test('Uses concrete explanation style for behavior warnings', () {
      final input = {
        'behavior_penalty': 0.2,
        'affordability_score': 90.0,
        'risk_breakdown': {
          'behavior': 20.0,
          'affordability': 1.0,
          'goal_impact': 0.0,
        },
      };

      final result = DecisionTranslator.translate(
        input,
        explanationStyle: 'concrete',
      );
      expect(result.verdict, 'Delay');
      expect(
        result.primaryReason,
        'Your recent pattern shows purchases like this are often regretted.',
      );
      expect(result.recommendedAction, 'delay');
    });
  });
}
