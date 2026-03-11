import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/create_custom_goal_screen.dart';
import 'screens/decision_analysis_screen.dart';
import 'screens/decision_input_screen.dart';
import 'screens/define_your_goal_screen.dart';
import 'screens/fixed_expenses_screen.dart';
import 'screens/goal_motivation_screen.dart';
import 'screens/goals_hub_screen.dart';
import 'screens/habits_screen.dart';
import 'screens/home_screen.dart';
import 'screens/income_setup_screen.dart';
import 'screens/purchase_reflection_screen.dart';
import 'screens/ready_to_start_screen.dart';
import 'screens/welcome_screen.dart';

GoRouter createRouter(String initialLoc) {
  return GoRouter(
    initialLocation: initialLoc,
    routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/income_setup',
      builder: (context, state) => const IncomeSetupScreen(),
    ),
    GoRoute(
      path: '/fixed_expenses',
      builder: (context, state) => const FixedExpensesScreen(),
    ),
    GoRoute(
      path: '/define_your_goal',
      builder: (context, state) => const DefineYourGoalScreen(),
    ),
    GoRoute(
      path: '/create_custom_goal',
      builder: (context, state) => const CreateCustomGoalScreen(),
    ),
    GoRoute(
      path: '/goal_motivation',
      builder: (context, state) => const GoalMotivationScreen(),
    ),
    GoRoute(
      path: '/ready_to_start',
      builder: (context, state) => const ReadyToStartScreen(),
    ),
    GoRoute(
      path: '/decision_input',
      builder: (context, state) => const DecisionInputScreen(),
    ),
    GoRoute(
      path: '/decision_analysis',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>? ?? {};
        return DecisionAnalysisScreen(
          purchaseData: extras['purchaseData'],
          aiEvaluation: extras['aiEvaluation'],
        );
      },
    ),
    GoRoute(
      path: '/goals_hub',
      builder: (context, state) => const GoalsHubScreen(),
    ),
    GoRoute(
      path: '/habits',
      builder: (context, state) => const HabitsScreen(),
    ),
    GoRoute(
      path: '/purchase_reflection',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>? ?? {};
        return PurchaseReflectionScreen(
          purchaseId: extras['purchaseId'],
          itemName: extras['itemName'],
        );
      },
    ),
  ],
);
}
