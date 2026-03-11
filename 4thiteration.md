Iteration 4: Mobile Architecture
Refactor the Flutter application into a robust, layered architecture using Typed Models, Riverpod, and GoRouter.

User Review Required
IMPORTANT

This iteration involves a major reorganization of the lib/ directory and a transition from setState to Riverpod for all data-fetching screens.

Proposed Folder Structure
To prevent "file soup," the project will follow this structure:

text
lib/
  core/
    api/        # ApiService, client config
    errors/     # AppException and variants
    theme/      # App colors/styles
    utils/      # Extensions, formatters
  models/       # Typed Dart objects (JSON serializable)
  repositories/ # Low-level data access
  providers/    # State management logic
  screens/      # UI Layouts
  widgets/      # Reusable UI components
Proposed Changes
[Core & Infrastructure]
Establish the networking and error handling foundations.

[NEW] 
app_exception.dart
Define a sealed class hierarchy: AppException (Network, Auth, Api, Unknown).

[MODIFY] 
api_service.dart
 [MOVE]
Move from lib/services/ to lib/core/api/. Refactor to catch raw exceptions and throw typed AppException variants. Handle token injection and base URL logic.

[Models & State Management]
Add dependencies and implement the data layer.

[MODIFY] 
pubspec.yaml
Add: flutter_riverpod, go_router, json_annotation, json_serializable, build_runner, freezed_annotation, freezed.

[NEW] 
Models
Create user.dart, goal.dart, purchase.dart, insight.dart with json_serializable.

[NEW] 
Repositories
Implement ApiRepository to provide high-level methods (e.g., 
getGoals()
) that handle domain-specific logic and return models.

[NEW] 
Providers
auth_provider.dart: Session management and persistence.
user_provider.dart: Current user data.
goals_provider.dart: User savings goals.
purchases_provider.dart: History and latest evaluations.
insights_provider.dart: Habits and LLM insights.
[Navigation & UI Migration]
Modernize the UI interaction layer.

[MODIFY] 
main.dart
Setup ProviderScope and implement GoRouter with defined routes for all existing screens.

[MODIFY] 
Screens Migration
Migrate all data-fetching screens (HabitsScreen, GoalsHubScreen, 
HomeScreen
, etc.) to use ConsumerWidget and Riverpod AsyncValue (loading/error/data).

Verification Plan
Automated Tests
Unit Tests: Test 
ApiService
 error mapping and ApiRepository model parsing.
Provider Tests: Mock the repository to test state transitions in providers.
Manual Verification
Auth Persistence: Login → Kill App → Reopen → Verify still logged in.
Error Handling: Disable internet → Verify typed "Network Error" UI appears with a Retry button.
Navigation: Verify persistent navigation (if used) or smooth GoRouter transitions.
