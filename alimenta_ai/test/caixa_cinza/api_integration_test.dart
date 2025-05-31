import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Mock classes for integration testing
@GenerateMocks([http.Client])
import 'api_integration_test.mocks.dart';

/// Gray-box integration testing for API operations
/// Tests API integration with partial knowledge of internal implementation
void main() {
  group('🧪 API Integration Gray-box Tests', () {
    late MockClient mockHttpClient;

    setUp(() {
      print('🧪 [${DateTime.now()}] Setting up API integration test environment');
      mockHttpClient = MockClient();
    });

    tearDown(() {
      print('🧹 [${DateTime.now()}] Cleaning up API integration test environment');
      reset(mockHttpClient);
    });

    testWidgets('Should handle complete user authentication flow', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Testing complete user authentication flow');
      final stopwatch = Stopwatch()..start();      // Mock successful login API response with delay to test loading state
      when(mockHttpClient.post(
        Uri.parse('https://api.alimenta-ai.com/auth/login'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 500)); // Add delay for loading state
        return http.Response(
          jsonEncode({
            'success': true,
            'token': 'mock_jwt_token_12345',
            'user': {
              'id': '123',
              'name': 'Test User',
              'email': 'test@example.com',
            },
          }),
          200,
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: _AuthenticationFlowWidget(httpClient: mockHttpClient),
        ),
      );

      // Test login form
      await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      print('📊 [${DateTime.now()}] Login credentials entered');      // Submit login form
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump(); // Processa o setState inicial
      await tester.pump(const Duration(milliseconds: 100)); // Aguarda o estado de loading

      // Check loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Signing in...'), findsOneWidget);
      print('📊 [${DateTime.now()}] Loading state displayed during API call');

      // Wait for API response
      await tester.pumpAndSettle();

      // Verify API call was made with correct parameters
      verify(mockHttpClient.post(
        Uri.parse('https://api.alimenta-ai.com/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': 'test@example.com',
          'password': 'password123',
        }),
      )).called(1);

      // Check successful login state
      expect(find.text('Welcome, Test User!'), findsOneWidget);
      expect(find.text('Login successful'), findsOneWidget);
      print('📊 [${DateTime.now()}] Successful authentication flow completed');

      stopwatch.stop();
      print('📊 [${DateTime.now()}] Authentication flow test completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('Should handle user profile data synchronization', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Testing user profile data sync');
      final stopwatch = Stopwatch()..start();      // Mock profile fetch API with delay
      when(mockHttpClient.get(
        Uri.parse('https://api.alimenta-ai.com/users/123'),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 500)); // Add delay for loading state
        return http.Response(
          jsonEncode({
            'id': '123',
            'name': 'John Doe',
            'email': 'john@example.com',
            'preferences': {
              'diet_type': 'vegetarian',
              'allergies': ['nuts', 'dairy'],
              'calorie_goal': 2000,
            },
            'last_updated': '2024-01-15T10:30:00Z',
          }),
          200,
        );
      });      // Mock profile update API
      when(mockHttpClient.put(
        Uri.parse('https://api.alimenta-ai.com/users/123'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 500)); // Add delay for loading state
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Profile updated successfully',
          }),
          200,
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: _ProfileSyncWidget(httpClient: mockHttpClient),
        ),
      );      // Trigger profile load
      await tester.tap(find.byKey(const Key('load_profile_button')));
      await tester.pump(); // Processa o setState inicial
      await tester.pump(const Duration(milliseconds: 100)); // Aguarda o estado de loading

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      print('📊 [${DateTime.now()}] Profile loading initiated');

      await tester.pumpAndSettle();

      // Verify profile data is displayed
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('john@example.com'), findsOneWidget);
      expect(find.text('Diet: vegetarian'), findsOneWidget);
      expect(find.text('Calorie Goal: 2000'), findsOneWidget);
      print('📊 [${DateTime.now()}] Profile data loaded and displayed');

      // Test profile update
      await tester.tap(find.byKey(const Key('edit_profile_button')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('name_field')), 'John Smith');
      await tester.enterText(find.byKey(const Key('calorie_goal_field')), '2200');

      await tester.tap(find.byKey(const Key('save_profile_button')));
      await tester.pump();

      expect(find.text('Saving changes...'), findsOneWidget);
      print('📊 [${DateTime.now()}] Profile update initiated');

      await tester.pumpAndSettle();      // Verify API calls
      verify(mockHttpClient.get(
        Uri.parse('https://api.alimenta-ai.com/users/123'),
        headers: anyNamed('headers'),
      )).called(2); // Called twice: initial load + reload after save

      verify(mockHttpClient.put(
        Uri.parse('https://api.alimenta-ai.com/users/123'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).called(1);      expect(find.text('Profile updated successfully'), findsOneWidget);
      print('📊 [${DateTime.now()}] Profile sync completed successfully');

      // Wait for any pending async operations to complete
      await tester.pump(const Duration(milliseconds: 600)); // Wait longer than the 500ms delay
      await tester.pumpAndSettle();

      stopwatch.stop();
      print('📊 [${DateTime.now()}] Profile sync test completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('Should handle nutrition data fetch and caching', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Testing nutrition data integration');
      final stopwatch = Stopwatch()..start();      // Mock nutrition API response with delay
      when(mockHttpClient.get(
        Uri.parse('https://api.alimenta-ai.com/nutrition/search?query=apple'),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 500)); // Add delay for loading state
        return http.Response(
          jsonEncode({
            'results': [
              {
                'id': 'food_001',
                'name': 'Apple',
                'calories_per_100g': 52,
                'protein': 0.3,
                'carbs': 14,
                'fat': 0.2,
                'fiber': 2.4,
              },
              {
                'id': 'food_002',
                'name': 'Green Apple',
                'calories_per_100g': 50,
                'protein': 0.4,
                'carbs': 13,
                'fat': 0.1,
                'fiber': 2.8,
              },
            ],
            'total_results': 2,
            'cached_at': '2024-01-15T10:30:00Z',
          }),
          200,
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: _NutritionSearchWidget(httpClient: mockHttpClient),
        ),
      );      // Test search functionality
      await tester.enterText(find.byKey(const Key('search_field')), 'apple');
      await tester.tap(find.byKey(const Key('search_button')));
      await tester.pump(); // Processa o setState inicial
      await tester.pump(const Duration(milliseconds: 100)); // Aguarda o estado de loading

      expect(find.text('Searching for nutrition data...'), findsOneWidget);
      print('📊 [${DateTime.now()}] Nutrition search initiated');

      await tester.pumpAndSettle();

      // Verify search results
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Green Apple'), findsOneWidget);
      expect(find.text('52 cal/100g'), findsOneWidget);
      expect(find.text('50 cal/100g'), findsOneWidget);
      print('📊 [${DateTime.now()}] Search results displayed correctly');

      // Test item selection
      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();

      expect(find.text('Selected: Apple'), findsOneWidget);
      expect(find.text('Calories: 52 per 100g'), findsOneWidget);
      expect(find.text('Protein: 0.3g'), findsOneWidget);
      expect(find.text('Carbs: 14g'), findsOneWidget);
      print('📊 [${DateTime.now()}] Item selection and details displayed');

      // Verify API call
      verify(mockHttpClient.get(
        Uri.parse('https://api.alimenta-ai.com/nutrition/search?query=apple'),
        headers: anyNamed('headers'),
      )).called(1);

      stopwatch.stop();
      print('📊 [${DateTime.now()}] Nutrition data integration test completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('Should handle meal logging with API synchronization', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Testing meal logging integration');
      final stopwatch = Stopwatch()..start();      // Mock meal logging API
      when(mockHttpClient.post(
        Uri.parse('https://api.alimenta-ai.com/meals'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 500)); // Delay para manter loading visível
        return http.Response(
          jsonEncode({
            'success': true,
            'meal_id': 'meal_12345',
            'message': 'Meal logged successfully',
            'calories_added': 520,
            'daily_total': 1450,
          }),
          200,
        );
      });

      // Mock daily summary API
      when(mockHttpClient.get(
        Uri.parse('https://api.alimenta-ai.com/meals/daily-summary?date=2024-01-15'),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 500)); // Delay para manter loading visível
        return http.Response(
          jsonEncode({
            'date': '2024-01-15',
            'total_calories': 1450,
            'goal_calories': 2000,
            'meals': [
              {
                'id': 'meal_12345',
                'name': 'Breakfast',
                'foods': ['Apple', 'Oatmeal'],
                'calories': 520,
                'logged_at': '2024-01-15T08:30:00Z',
              }
            ],
          }),
          200,
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: _MealLoggingWidget(httpClient: mockHttpClient),
        ),
      );

      // Test meal logging
      await tester.enterText(find.byKey(const Key('meal_name_field')), 'Breakfast');
      await tester.enterText(find.byKey(const Key('food_items_field')), 'Apple, Oatmeal');
      await tester.enterText(find.byKey(const Key('calories_field')), '520');      await tester.tap(find.byKey(const Key('log_meal_button')));
      await tester.pump(); // Processa o setState inicial
      await tester.pump(const Duration(milliseconds: 100)); // Aguarda o estado de loading

      expect(find.text('Logging meal...'), findsOneWidget);
      print('📊 [${DateTime.now()}] Meal logging initiated');      await tester.pumpAndSettle();

      expect(find.textContaining('Meal logged successfully!'), findsOneWidget);
      expect(find.textContaining('Calories added: 520'), findsOneWidget);
      expect(find.textContaining('Daily total: 1450'), findsOneWidget);
      print('📊 [${DateTime.now()}] Meal logged successfully');

      // Test daily summary refresh
      await tester.tap(find.byKey(const Key('refresh_summary_button')));
      await tester.pump();

      await tester.pumpAndSettle();

      expect(find.text('Daily Summary'), findsOneWidget);
      expect(find.text('Total: 1450 / 2000 calories'), findsOneWidget);
      expect(find.text('Breakfast - 520 cal'), findsOneWidget);
      print('📊 [${DateTime.now()}] Daily summary refreshed');

      // Verify API calls
      verify(mockHttpClient.post(
        Uri.parse('https://api.alimenta-ai.com/meals'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).called(1);

      verify(mockHttpClient.get(
        Uri.parse('https://api.alimenta-ai.com/meals/daily-summary?date=2024-01-15'),
        headers: anyNamed('headers'),
      )).called(1);

      stopwatch.stop();
      print('📊 [${DateTime.now()}] Meal logging integration test completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('Should handle offline to online data synchronization', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Testing offline to online sync');
      final stopwatch = Stopwatch()..start();      // Mock sync API response
      when(mockHttpClient.post(
        Uri.parse('https://api.alimenta-ai.com/sync'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 500)); // Delay para manter loading visível
        return http.Response(
          jsonEncode({
            'success': true,
            'synced_items': 3,
            'conflicts_resolved': 1,
            'last_sync': '2024-01-15T12:00:00Z',
          }),
          200,
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: _OfflineSyncWidget(httpClient: mockHttpClient),
        ),
      );      // Simulate offline data accumulation
      await tester.tap(find.byKey(const Key('add_offline_data_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('add_offline_data_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('add_offline_data_button')));
      await tester.pump();

      expect(find.text('Offline items: 3'), findsOneWidget);
      print('📊 [${DateTime.now()}] Offline data accumulated');      // Test sync when coming online      
      await tester.tap(find.byKey(const Key('sync_button')));
      await tester.pump(); // Processa o setState inicial - o botão deve ter disparado _syncData()
      
      // O loading state deveria estar visível agora
      expect(find.text('Syncing data...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      print('📊 [${DateTime.now()}] Sync process initiated');await tester.pumpAndSettle();

      expect(find.textContaining('Sync completed successfully'), findsOneWidget);
      expect(find.textContaining('3 items synced'), findsOneWidget);
      expect(find.textContaining('1 conflict resolved'), findsOneWidget);
      expect(find.text('Offline items: 0'), findsOneWidget);
      print('📊 [${DateTime.now()}] Sync completed successfully');

      // Verify sync API call
      verify(mockHttpClient.post(
        Uri.parse('https://api.alimenta-ai.com/sync'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).called(1);

      stopwatch.stop();
      print('📊 [${DateTime.now()}] Offline sync test completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('Should handle API error scenarios with proper recovery', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Testing API error handling');
      final stopwatch = Stopwatch()..start();      // Mock API error responses
      when(mockHttpClient.get(
        Uri.parse('https://api.alimenta-ai.com/data'),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 500)); // Delay para manter loading visível
        return http.Response(
          jsonEncode({'error': 'Internal server error'}),
          500,
        );
      });

      // Mock retry success
      when(mockHttpClient.get(
        Uri.parse('https://api.alimenta-ai.com/data-retry'),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 500)); // Delay para manter loading visível
        return http.Response(
          jsonEncode({
            'data': ['item1', 'item2', 'item3'],
            'status': 'success',
          }),
          200,
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: _ErrorHandlingWidget(httpClient: mockHttpClient),
        ),
      );      // Test initial API failure
      await tester.tap(find.byKey(const Key('fetch_data_button')));
      await tester.pump(); // Processa o setState inicial
      await tester.pump(const Duration(milliseconds: 100)); // Aguarda o estado de loading

      expect(find.text('Loading data...'), findsOneWidget);
      print('📊 [${DateTime.now()}] Data loading initiated');      await tester.pumpAndSettle();

      expect(find.textContaining('Error: Failed to load data'), findsOneWidget);
      expect(find.textContaining('Server returned: Internal server error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      print('📊 [${DateTime.now()}] Error state displayed with retry option');

      // Test retry mechanism
      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(find.text('Retrying...'), findsOneWidget);
      print('📊 [${DateTime.now()}] Retry initiated');      await tester.pumpAndSettle();

      expect(find.textContaining('Data loaded successfully!'), findsOneWidget);
      expect(find.textContaining('Items: item1, item2, item3'), findsOneWidget);
      print('📊 [${DateTime.now()}] Retry successful');

      // Verify API calls
      verify(mockHttpClient.get(
        Uri.parse('https://api.alimenta-ai.com/data'),
        headers: anyNamed('headers'),
      )).called(1);

      verify(mockHttpClient.get(
        Uri.parse('https://api.alimenta-ai.com/data-retry'),
        headers: anyNamed('headers'),
      )).called(1);

      stopwatch.stop();
      print('📊 [${DateTime.now()}] API error handling test completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('Should handle real-time data updates via API polling', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Testing real-time data updates');
      final stopwatch = Stopwatch()..start();

      int callCount = 0;
        // Mock polling API with changing data
      when(mockHttpClient.get(
        Uri.parse('https://api.alimenta-ai.com/realtime-data'),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 300)); // Delay menor para polling
        callCount++;
        return http.Response(
          jsonEncode({
            'timestamp': DateTime.now().toIso8601String(),
            'data': 'Update #$callCount',
            'version': callCount,
          }),
          200,
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: _RealTimeDataWidget(httpClient: mockHttpClient),
        ),
      );      // Start real-time updates
      await tester.tap(find.byKey(const Key('start_updates_button')));
      await tester.pump(); // Processa o setState inicial
      await tester.pump(const Duration(milliseconds: 100)); // Aguarda o estado inicial

      expect(find.text('Real-time updates started'), findsOneWidget);
      print('📊 [${DateTime.now()}] Real-time updates started');      // Wait for first update - aguarda mais tempo para garantir que o timer execute
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(); // Process the HTTP call
      await tester.pumpAndSettle();

      expect(find.text('Latest: Update #1'), findsOneWidget);
      print('📊 [${DateTime.now()}] First update received');

      // Wait for second update  
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(); // Process the HTTP call
      await tester.pumpAndSettle();

      expect(find.text('Latest: Update #2'), findsOneWidget);
      print('📊 [${DateTime.now()}] Second update received');      // Stop updates
      await tester.tap(find.byKey(const Key('stop_updates_button')));
      await tester.pumpAndSettle();

      expect(find.text('Real-time updates stopped'), findsOneWidget);
      print('📊 [${DateTime.now()}] Real-time updates stopped');

      // Wait for any pending timers to complete
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Verify multiple API calls were made
      verify(mockHttpClient.get(
        Uri.parse('https://api.alimenta-ai.com/realtime-data'),
        headers: anyNamed('headers'),
      )).called(greaterThan(1));

      stopwatch.stop();
      print('📊 [${DateTime.now()}] Real-time data updates test completed in ${stopwatch.elapsedMilliseconds}ms');
    });
  });
}

// Helper widgets for API integration testing

class _AuthenticationFlowWidget extends StatefulWidget {
  final http.Client httpClient;

  const _AuthenticationFlowWidget({required this.httpClient});

  @override
  State<_AuthenticationFlowWidget> createState() => _AuthenticationFlowWidgetState();
}

class _AuthenticationFlowWidgetState extends State<_AuthenticationFlowWidget> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _user;
  String? _message;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final response = await widget.httpClient.post(
        Uri.parse('https://api.alimenta-ai.com/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        setState(() {
          _user = data['user']['name'];
          _message = 'Login successful';
        });
      } else {
        setState(() {
          _message = 'Login failed';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Authentication Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_user != null) ...[
              Text('Welcome, $_user!'),
              if (_message != null) Text(_message!),
            ] else ...[
              TextField(
                key: const Key('email_field'),
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                key: const Key('password_field'),
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              if (_isLoading) ...[
                const CircularProgressIndicator(),
                const Text('Signing in...'),
              ] else ...[
                ElevatedButton(
                  key: const Key('login_button'),
                  onPressed: _login,
                  child: const Text('Login'),
                ),
              ],
              if (_message != null) Text(_message!),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileSyncWidget extends StatefulWidget {
  final http.Client httpClient;

  const _ProfileSyncWidget({required this.httpClient});

  @override
  State<_ProfileSyncWidget> createState() => _ProfileSyncWidgetState();
}

class _ProfileSyncWidgetState extends State<_ProfileSyncWidget> {
  Map<String, dynamic>? _profile;
  bool _isLoading = false;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _message;
  
  final _nameController = TextEditingController();
  final _calorieGoalController = TextEditingController();

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await widget.httpClient.get(
        Uri.parse('https://api.alimenta-ai.com/users/123'),
        headers: {'Authorization': 'Bearer mock_token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _profile = jsonDecode(response.body);
          _nameController.text = _profile!['name'];
          _calorieGoalController.text = _profile!['preferences']['calorie_goal'].toString();
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error loading profile: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final response = await widget.httpClient.put(
        Uri.parse('https://api.alimenta-ai.com/users/123'),
        headers: {
          'Authorization': 'Bearer mock_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': _nameController.text,
          'preferences': {
            'calorie_goal': int.parse(_calorieGoalController.text),
          },
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _message = 'Profile updated successfully';
          _isEditing = false;
        });
        await _loadProfile();
      }
    } catch (e) {
      setState(() {
        _message = 'Error saving profile: $e';
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Sync Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_profile == null) ...[
              ElevatedButton(
                key: const Key('load_profile_button'),
                onPressed: _isLoading ? null : _loadProfile,
                child: const Text('Load Profile'),
              ),
              if (_isLoading) ...[
                const CircularProgressIndicator(),
                const Text('Loading profile...'),
              ],
            ] else ...[
              if (!_isEditing) ...[
                Text(_profile!['name']),
                Text(_profile!['email']),
                Text('Diet: ${_profile!['preferences']['diet_type']}'),
                Text('Calorie Goal: ${_profile!['preferences']['calorie_goal']}'),
                ElevatedButton(
                  key: const Key('edit_profile_button'),
                  onPressed: () => setState(() => _isEditing = true),
                  child: const Text('Edit Profile'),
                ),
              ] else ...[
                TextField(
                  key: const Key('name_field'),
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  key: const Key('calorie_goal_field'),
                  controller: _calorieGoalController,
                  decoration: const InputDecoration(labelText: 'Calorie Goal'),
                  keyboardType: TextInputType.number,
                ),
                if (_isSaving) ...[
                  const CircularProgressIndicator(),
                  const Text('Saving changes...'),
                ] else ...[
                  ElevatedButton(
                    key: const Key('save_profile_button'),
                    onPressed: _saveProfile,
                    child: const Text('Save Changes'),
                  ),
                ],
              ],
            ],
            if (_message != null) Text(_message!),
          ],
        ),
      ),
    );
  }
}

class _NutritionSearchWidget extends StatefulWidget {
  final http.Client httpClient;

  const _NutritionSearchWidget({required this.httpClient});

  @override
  State<_NutritionSearchWidget> createState() => _NutritionSearchWidgetState();
}

class _NutritionSearchWidgetState extends State<_NutritionSearchWidget> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  Map<String, dynamic>? _selectedItem;
  bool _isSearching = false;

  Future<void> _search() async {
    setState(() {
      _isSearching = true;
      _results.clear();
    });

    try {
      final response = await widget.httpClient.get(
        Uri.parse('https://api.alimenta-ai.com/nutrition/search?query=${_searchController.text}'),
        headers: {'Authorization': 'Bearer mock_token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _results = List<Map<String, dynamic>>.from(data['results']);
        });
      }
    } catch (e) {
      print('Search error: $e');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition Search Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('search_field'),
                    controller: _searchController,
                    decoration: const InputDecoration(labelText: 'Search food'),
                  ),
                ),
                ElevatedButton(
                  key: const Key('search_button'),
                  onPressed: _search,
                  child: const Text('Search'),
                ),
              ],
            ),
            if (_isSearching) ...[
              const CircularProgressIndicator(),
              const Text('Searching for nutrition data...'),
            ],
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final item = _results[index];
                  return ListTile(
                    title: Text(item['name']),
                    subtitle: Text('${item['calories_per_100g']} cal/100g'),
                    onTap: () => setState(() => _selectedItem = item),
                  );
                },
              ),
            ),
            if (_selectedItem != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Selected: ${_selectedItem!['name']}'),
                      Text('Calories: ${_selectedItem!['calories_per_100g']} per 100g'),
                      Text('Protein: ${_selectedItem!['protein']}g'),
                      Text('Carbs: ${_selectedItem!['carbs']}g'),
                      Text('Fat: ${_selectedItem!['fat']}g'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MealLoggingWidget extends StatefulWidget {
  final http.Client httpClient;

  const _MealLoggingWidget({required this.httpClient});

  @override
  State<_MealLoggingWidget> createState() => _MealLoggingWidgetState();
}

class _MealLoggingWidgetState extends State<_MealLoggingWidget> {
  final _mealNameController = TextEditingController();
  final _foodItemsController = TextEditingController();
  final _caloriesController = TextEditingController();
  
  bool _isLogging = false;
  Map<String, dynamic>? _dailySummary;
  String? _message;

  Future<void> _logMeal() async {
    setState(() {
      _isLogging = true;
      _message = null;
    });

    try {
      final response = await widget.httpClient.post(
        Uri.parse('https://api.alimenta-ai.com/meals'),
        headers: {
          'Authorization': 'Bearer mock_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': _mealNameController.text,
          'foods': _foodItemsController.text.split(',').map((e) => e.trim()).toList(),
          'calories': int.parse(_caloriesController.text),
          'date': DateTime.now().toIso8601String().split('T')[0],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _message = 'Meal logged successfully!\nCalories added: ${data['calories_added']}\nDaily total: ${data['daily_total']}';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error logging meal: $e';
      });
    } finally {
      setState(() {
        _isLogging = false;
      });
    }
  }

  Future<void> _refreshSummary() async {
    try {
      final response = await widget.httpClient.get(
        Uri.parse('https://api.alimenta-ai.com/meals/daily-summary?date=2024-01-15'),
        headers: {'Authorization': 'Bearer mock_token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _dailySummary = jsonDecode(response.body);
        });
      }
    } catch (e) {
      print('Error refreshing summary: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meal Logging Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              key: const Key('meal_name_field'),
              controller: _mealNameController,
              decoration: const InputDecoration(labelText: 'Meal Name'),
            ),
            TextField(
              key: const Key('food_items_field'),
              controller: _foodItemsController,
              decoration: const InputDecoration(labelText: 'Food Items (comma separated)'),
            ),
            TextField(
              key: const Key('calories_field'),
              controller: _caloriesController,
              decoration: const InputDecoration(labelText: 'Calories'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            if (_isLogging) ...[
              const CircularProgressIndicator(),
              const Text('Logging meal...'),
            ] else ...[
              ElevatedButton(
                key: const Key('log_meal_button'),
                onPressed: _logMeal,
                child: const Text('Log Meal'),
              ),
            ],
            if (_message != null) Text(_message!),
            const SizedBox(height: 16),
            ElevatedButton(
              key: const Key('refresh_summary_button'),
              onPressed: _refreshSummary,
              child: const Text('Refresh Daily Summary'),
            ),
            if (_dailySummary != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Daily Summary', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Total: ${_dailySummary!['total_calories']} / ${_dailySummary!['goal_calories']} calories'),
                      ...(_dailySummary!['meals'] as List).map((meal) =>
                        Text('${meal['name']} - ${meal['calories']} cal')
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OfflineSyncWidget extends StatefulWidget {
  final http.Client httpClient;

  const _OfflineSyncWidget({required this.httpClient});

  @override
  State<_OfflineSyncWidget> createState() => _OfflineSyncWidgetState();
}

class _OfflineSyncWidgetState extends State<_OfflineSyncWidget> {
  int _offlineItems = 0;
  bool _isSyncing = false;
  String? _syncMessage;

  void _addOfflineData() {
    setState(() {
      _offlineItems++;
    });
  }

  Future<void> _syncData() async {
    setState(() {
      _isSyncing = true;
      _syncMessage = null;
    });

    try {
      final response = await widget.httpClient.post(
        Uri.parse('https://api.alimenta-ai.com/sync'),
        headers: {
          'Authorization': 'Bearer mock_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'offline_items': _offlineItems,
          'device_id': 'test_device',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _syncMessage = 'Sync completed successfully\n${data['synced_items']} items synced\n${data['conflicts_resolved']} conflict resolved';
          _offlineItems = 0;
        });
      }
    } catch (e) {
      setState(() {
        _syncMessage = 'Sync failed: $e';
      });
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline Sync Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Offline items: $_offlineItems'),
            ElevatedButton(
              key: const Key('add_offline_data_button'),
              onPressed: _addOfflineData,
              child: const Text('Add Offline Data'),
            ),
            const SizedBox(height: 16),
            if (_isSyncing) ...[
              const CircularProgressIndicator(),
              const Text('Syncing data...'),
            ] else ...[
              ElevatedButton(
                key: const Key('sync_button'),
                onPressed: _offlineItems > 0 ? _syncData : null,
                child: const Text('Sync Data'),
              ),
            ],
            if (_syncMessage != null) Text(_syncMessage!),
          ],
        ),
      ),
    );
  }
}

class _ErrorHandlingWidget extends StatefulWidget {
  final http.Client httpClient;

  const _ErrorHandlingWidget({required this.httpClient});

  @override
  State<_ErrorHandlingWidget> createState() => _ErrorHandlingWidgetState();
}

class _ErrorHandlingWidgetState extends State<_ErrorHandlingWidget> {
  bool _isLoading = false;
  bool _isRetrying = false;
  String? _data;
  String? _error;

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _data = null;
    });

    try {
      final response = await widget.httpClient.get(
        Uri.parse('https://api.alimenta-ai.com/data'),
        headers: {'Authorization': 'Bearer mock_token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _data = 'Data loaded successfully!\nItems: ${data['data'].join(', ')}';
        });
      } else {
        final error = jsonDecode(response.body);
        setState(() {
          _error = 'Error: Failed to load data\nServer returned: ${error['error']}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _retryFetch() async {
    setState(() {
      _isRetrying = true;
      _error = null;
      _data = null;
    });

    try {
      final response = await widget.httpClient.get(
        Uri.parse('https://api.alimenta-ai.com/data-retry'),
        headers: {'Authorization': 'Bearer mock_token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _data = 'Data loaded successfully!\nItems: ${data['data'].join(', ')}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Retry failed: $e';
      });
    } finally {
      setState(() {
        _isRetrying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error Handling Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_isLoading) ...[
              const CircularProgressIndicator(),
              const Text('Loading data...'),
            ] else if (_isRetrying) ...[
              const CircularProgressIndicator(),
              const Text('Retrying...'),
            ] else if (_error != null) ...[
              Text(_error!),
              ElevatedButton(
                onPressed: _retryFetch,
                child: const Text('Retry'),
              ),
            ] else if (_data != null) ...[
              Text(_data!),
            ] else ...[
              ElevatedButton(
                key: const Key('fetch_data_button'),
                onPressed: _fetchData,
                child: const Text('Fetch Data'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RealTimeDataWidget extends StatefulWidget {
  final http.Client httpClient;

  const _RealTimeDataWidget({required this.httpClient});

  @override
  State<_RealTimeDataWidget> createState() => _RealTimeDataWidgetState();
}

class _RealTimeDataWidgetState extends State<_RealTimeDataWidget> {
  String? _latestData;
  bool _isPolling = false;
  String? _status;

  void _startUpdates() {
    setState(() {
      _isPolling = true;
      _status = 'Real-time updates started';
    });
    _pollForUpdates();
  }

  void _stopUpdates() {
    setState(() {
      _isPolling = false;
      _status = 'Real-time updates stopped';
    });
  }

  Future<void> _pollForUpdates() async {
    while (_isPolling) {
      try {
        final response = await widget.httpClient.get(
          Uri.parse('https://api.alimenta-ai.com/realtime-data'),
          headers: {'Authorization': 'Bearer mock_token'},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (mounted) {
            setState(() {
              _latestData = data['data'];
            });
          }
        }      } catch (e) {
        print('Polling error: $e');
      }

      // Only delay if still polling
      if (_isPolling) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Real-time Data Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (!_isPolling) ...[
              ElevatedButton(
                key: const Key('start_updates_button'),
                onPressed: _startUpdates,
                child: const Text('Start Real-time Updates'),
              ),
            ] else ...[
              ElevatedButton(
                key: const Key('stop_updates_button'),
                onPressed: _stopUpdates,
                child: const Text('Stop Updates'),
              ),
            ],
            if (_status != null) Text(_status!),
            if (_latestData != null) ...[
              const SizedBox(height: 16),
              Text('Latest: $_latestData'),
            ],
          ],
        ),
      ),
    );
  }
}
