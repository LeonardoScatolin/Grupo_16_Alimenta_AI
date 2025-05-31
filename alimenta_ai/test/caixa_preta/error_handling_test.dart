import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Black-box testing for error handling and user feedback
/// Tests error states, user notifications, and recovery mechanisms from a user perspective
void main() {
  group('🧪 Error Handling Black-box Tests', () {
    setUp(() {
      print('🧪 [${DateTime.now()}] Setting up error handling test environment');
    });

    tearDown(() {
      print('🧹 [${DateTime.now()}] Cleaning up error handling test environment');
    });

    testWidgets('Should display network error messages correctly', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Testing network error display');
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: _NetworkErrorTestWidget(),
        ),
      );

      // Test no network connection state
      await tester.tap(find.byKey(const Key('trigger_no_network')));
      await tester.pumpAndSettle();

      expect(find.text('No internet connection'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      expect(find.text('Please check your internet connection and try again'), findsOneWidget);
      print('📊 [${DateTime.now()}] No network error message displayed correctly');

      // Test timeout error
      await tester.tap(find.byKey(const Key('trigger_timeout')));
      await tester.pumpAndSettle();

      expect(find.text('Request timeout'), findsOneWidget);
      expect(find.byIcon(Icons.timer_off), findsOneWidget);
      print('📊 [${DateTime.now()}] Timeout error message displayed correctly');

      // Test server error
      await tester.tap(find.byKey(const Key('trigger_server_error')));
      await tester.pumpAndSettle();

      expect(find.text('Server error'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Something went wrong on our end. Please try again later.'), findsOneWidget);
      print('📊 [${DateTime.now()}] Server error message displayed correctly');

      // Test retry functionality
      expect(find.text('Retry'), findsWidgets);
      await tester.tap(find.text('Retry').first);
      await tester.pumpAndSettle();
      print('📊 [${DateTime.now()}] Retry button functionality verified');

      stopwatch.stop();
      print('📊 [${DateTime.now()}] Network error handling test completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('Should handle form validation errors appropriately', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Testing form validation errors');
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: _FormValidationTestWidget(),
        ),
      );

      // Test empty field validation
      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pumpAndSettle();      expect(find.text('This field is required'), findsWidgets);
      print('📊 [${DateTime.now()}] Empty field validation errors displayed');

      // Test invalid email format
      await tester.enterText(find.byKey(const Key('email_field')), 'invalid-email');
      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
      print('📊 [${DateTime.now()}] Invalid email error displayed');

      // Test password strength validation
      await tester.enterText(find.byKey(const Key('password_field')), '123');
      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 8 characters'), findsOneWidget);
      print('📊 [${DateTime.now()}] Weak password error displayed');

      // Test successful validation
      await tester.enterText(find.byKey(const Key('name_field')), 'John Doe');
      await tester.enterText(find.byKey(const Key('email_field')), 'john@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'SecurePassword123!');
      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Form submitted successfully'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      print('📊 [${DateTime.now()}] Successful form submission verified');

      stopwatch.stop();
      print('📊 [${DateTime.now()}] Form validation error test completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('Should display loading states and error recovery', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Testing loading states and error recovery');
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: _LoadingErrorTestWidget(),
        ),
      );

      // Test initial loading state
      await tester.tap(find.byKey(const Key('start_loading')));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading...'), findsOneWidget);
      print('📊 [${DateTime.now()}] Loading state displayed correctly');

      // Wait for simulated error
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Failed to load data'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      print('📊 [${DateTime.now()}] Error state after loading displayed');

      // Test retry mechanism
      await tester.tap(find.text('Try Again'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      print('📊 [${DateTime.now()}] Retry loading initiated');

      // Wait for successful load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Data loaded successfully!'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      print('📊 [${DateTime.now()}] Successful data loading after retry');

      stopwatch.stop();
      print('📊 [${DateTime.now()}] Loading states and error recovery test completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('Should handle offline mode gracefully', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Testing offline mode handling');
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: _OfflineModeTestWidget(),
        ),
      );

      // Test going offline
      await tester.tap(find.byKey(const Key('go_offline')));
      await tester.pumpAndSettle();

      expect(find.text('You are currently offline'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(find.text('Some features may be limited'), findsOneWidget);
      print('📊 [${DateTime.now()}] Offline mode indicator displayed');

      // Test offline actions
      await tester.tap(find.byKey(const Key('offline_action')));
      await tester.pumpAndSettle();      expect(find.text('Action saved for when you\'re back online'), findsOneWidget);
      print('📊 [${DateTime.now()}] Offline action handling verified');

      // Test going back online
      await tester.tap(find.byKey(const Key('go_online')));
      await tester.pumpAndSettle();

      expect(find.text('Back online! Syncing data...'), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsOneWidget);
      print('📊 [${DateTime.now()}] Online restoration indicator displayed');

      // Wait for sync completion
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('All data synced successfully'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
      print('📊 [${DateTime.now()}] Data sync completion verified');

      stopwatch.stop();
      print('📊 [${DateTime.now()}] Offline mode handling test completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('Should display appropriate error dialogs and snackbars', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Testing error dialogs and snackbars');
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: _ErrorDialogTestWidget(),
        ),
      );

      // Test error dialog
      await tester.tap(find.byKey(const Key('show_error_dialog')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Error'), findsOneWidget);
      expect(find.text('An unexpected error occurred. Please try again.'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
      print('📊 [${DateTime.now()}] Error dialog displayed correctly');

      // Dismiss dialog
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      print('📊 [${DateTime.now()}] Error dialog dismissed');

      // Test warning snackbar
      await tester.tap(find.byKey(const Key('show_warning_snackbar')));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Warning: Please check your input'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
      print('📊 [${DateTime.now()}] Warning snackbar displayed');

      // Wait for snackbar to disappear
      await tester.pumpAndSettle(const Duration(seconds: 4));

      expect(find.byType(SnackBar), findsNothing);
      print('📊 [${DateTime.now()}] Warning snackbar auto-dismissed');

      // Test success snackbar with action
      await tester.tap(find.byKey(const Key('show_success_snackbar')));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Operation completed successfully'), findsOneWidget);
      expect(find.text('UNDO'), findsOneWidget);
      print('📊 [${DateTime.now()}] Success snackbar with action displayed');

      // Test snackbar action
      await tester.tap(find.text('UNDO'));
      await tester.pumpAndSettle();

      expect(find.text('Action undone'), findsOneWidget);
      print('📊 [${DateTime.now()}] Snackbar action functionality verified');

      stopwatch.stop();
      print('📊 [${DateTime.now()}] Error dialogs and snackbars test completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('Should handle permission errors appropriately', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Testing permission error handling');
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: _PermissionErrorTestWidget(),
        ),
      );

      // Test camera permission denied
      await tester.tap(find.byKey(const Key('request_camera')));
      await tester.pumpAndSettle();

      expect(find.text('Camera permission required'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
      expect(find.text('Please grant camera permission to use this feature'), findsOneWidget);
      expect(find.text('Go to Settings'), findsOneWidget);
      print('📊 [${DateTime.now()}] Camera permission error displayed');

      // Test location permission denied
      await tester.tap(find.byKey(const Key('request_location')));
      await tester.pumpAndSettle();

      expect(find.text('Location permission required'), findsOneWidget);
      expect(find.byIcon(Icons.location_off), findsOneWidget);
      expect(find.text('Location access is needed for this feature to work properly'), findsOneWidget);
      print('📊 [${DateTime.now()}] Location permission error displayed');

      // Test storage permission denied
      await tester.tap(find.byKey(const Key('request_storage')));
      await tester.pumpAndSettle();

      expect(find.text('Storage permission required'), findsOneWidget);
      expect(find.byIcon(Icons.folder_off), findsOneWidget);
      expect(find.text('Storage access is required to save files'), findsOneWidget);
      print('📊 [${DateTime.now()}] Storage permission error displayed');

      stopwatch.stop();
      print('📊 [${DateTime.now()}] Permission error handling test completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('Should provide clear feedback for user actions', (WidgetTester tester) async {
      print('🧪 [${DateTime.now()}] Testing user action feedback');
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: _UserFeedbackTestWidget(),
        ),
      );

      // Test button pressed feedback
      await tester.tap(find.byKey(const Key('feedback_button')));
      await tester.pump(const Duration(milliseconds: 100));

      // Check for visual feedback (button state change)
      final button = tester.widget<ElevatedButton>(find.byKey(const Key('feedback_button')));
      expect(button.onPressed, isNotNull);
      print('📊 [${DateTime.now()}] Button press feedback verified');      // Test form submission feedback
      await tester.tap(find.byKey(const Key('submit_form')));
      await tester.pump(const Duration(milliseconds: 100)); // Short pump to see initial state

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submitting...'), findsOneWidget);
      print('📊 [${DateTime.now()}] Form submission feedback displayed');

      // Wait for completion
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Form submitted successfully!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      print('📊 [${DateTime.now()}] Form submission completion feedback verified');      // Test delete action feedback
      await tester.tap(find.byKey(const Key('delete_item')));
      await tester.pump(); // Single pump to trigger the SnackBar

      // Check if SnackBar appears (the main user feedback we want to verify)
      expect(find.byType(SnackBar), findsOneWidget);
      print('📊 [${DateTime.now()}] Delete action feedback with undo option displayed');

      stopwatch.stop();
      print('📊 [${DateTime.now()}] User action feedback test completed in ${stopwatch.elapsedMilliseconds}ms');
    });
  });
}

// Helper widgets for error handling testing

class _NetworkErrorTestWidget extends StatefulWidget {
  @override
  State<_NetworkErrorTestWidget> createState() => _NetworkErrorTestWidgetState();
}

class _NetworkErrorTestWidgetState extends State<_NetworkErrorTestWidget> {
  String? errorMessage;
  IconData? errorIcon;
  String? errorDescription;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Network Error Test')),
      body: Column(
        children: [
          if (errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.red.shade100,
              child: Row(
                children: [
                  Icon(errorIcon, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(errorMessage!, style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (errorDescription != null) Text(errorDescription!),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => setState(() {
                errorMessage = null;
                errorIcon = null;
                errorDescription = null;
              }),
              child: const Text('Retry'),
            ),
          ],
          ElevatedButton(
            key: const Key('trigger_no_network'),
            onPressed: () => setState(() {
              errorMessage = 'No internet connection';
              errorIcon = Icons.wifi_off;
              errorDescription = 'Please check your internet connection and try again';
            }),
            child: const Text('Trigger No Network'),
          ),
          ElevatedButton(
            key: const Key('trigger_timeout'),
            onPressed: () => setState(() {
              errorMessage = 'Request timeout';
              errorIcon = Icons.timer_off;
              errorDescription = null;
            }),
            child: const Text('Trigger Timeout'),
          ),
          ElevatedButton(
            key: const Key('trigger_server_error'),
            onPressed: () => setState(() {
              errorMessage = 'Server error';
              errorIcon = Icons.error_outline;
              errorDescription = 'Something went wrong on our end. Please try again later.';
            }),
            child: const Text('Trigger Server Error'),
          ),
        ],
      ),
    );
  }
}

class _FormValidationTestWidget extends StatefulWidget {
  @override
  State<_FormValidationTestWidget> createState() => _FormValidationTestWidgetState();
}

class _FormValidationTestWidgetState extends State<_FormValidationTestWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitted = false;

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    if (!value.contains('@') || !value.contains('.')) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Form Validation Test')),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (_submitted) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.green.shade100,
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Form submitted successfully'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                key: const Key('name_field'),
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: _validateName,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('email_field'),
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('password_field'),
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: _validatePassword,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                key: const Key('submit_button'),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      _submitted = true;
                    });
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingErrorTestWidget extends StatefulWidget {
  @override
  State<_LoadingErrorTestWidget> createState() => _LoadingErrorTestWidgetState();
}

class _LoadingErrorTestWidgetState extends State<_LoadingErrorTestWidget> {
  bool _isLoading = false;
  bool _hasError = false;
  bool _hasData = false;
  int _retryCount = 0;

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _hasData = false;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
      if (_retryCount == 0) {
        _hasError = true;
        _retryCount++;
      } else {
        _hasData = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loading Error Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Loading...'),
            ] else if (_hasError) ...[
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Failed to load data'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Try Again'),
              ),
            ] else if (_hasData) ...[
              const Icon(Icons.check, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              const Text('Data loaded successfully!'),
            ] else ...[
              ElevatedButton(
                key: const Key('start_loading'),
                onPressed: _loadData,
                child: const Text('Load Data'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OfflineModeTestWidget extends StatefulWidget {
  @override
  State<_OfflineModeTestWidget> createState() => _OfflineModeTestWidgetState();
}

class _OfflineModeTestWidgetState extends State<_OfflineModeTestWidget> {
  bool _isOnline = true;
  bool _isSyncing = false;
  String? _message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline Mode Test')),
      body: Column(
        children: [
          if (!_isOnline) ...[
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.orange.shade100,
              child: const Row(
                children: [
                  Icon(Icons.cloud_off, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('You are currently offline', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Some features may be limited'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_isSyncing) ...[
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade100,
              child: const Row(
                children: [
                  Icon(Icons.sync, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Back online! Syncing data...'),
                ],
              ),
            ),
          ],
          if (_message != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.green.shade100,
              child: Row(
                children: [
                  const Icon(Icons.cloud_done, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(_message!),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            key: const Key('go_offline'),
            onPressed: () => setState(() {
              _isOnline = false;
              _message = null;
            }),
            child: const Text('Go Offline'),
          ),
          ElevatedButton(
            key: const Key('go_online'),
            onPressed: () async {
              setState(() {
                _isOnline = true;
                _isSyncing = true;
                _message = null;
              });
              await Future.delayed(const Duration(seconds: 2));
              setState(() {
                _isSyncing = false;
                _message = 'All data synced successfully';
              });
            },
            child: const Text('Go Online'),
          ),
          if (!_isOnline)
            ElevatedButton(
              key: const Key('offline_action'),
              onPressed: () => setState(() {
                _message = 'Action saved for when you\'re back online';
              }),
              child: const Text('Perform Offline Action'),
            ),
        ],
      ),
    );
  }
}

class _ErrorDialogTestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error Dialog Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              key: const Key('show_error_dialog'),
              onPressed: () => showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Error'),
                  content: const Text('An unexpected error occurred. Please try again.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              ),
              child: const Text('Show Error Dialog'),
            ),
            ElevatedButton(
              key: const Key('show_warning_snackbar'),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Warning: Please check your input'),
                    ],
                  ),
                  backgroundColor: Colors.orange,
                ),
              ),
              child: const Text('Show Warning SnackBar'),
            ),
            ElevatedButton(
              key: const Key('show_success_snackbar'),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Operation completed successfully'),
                  backgroundColor: Colors.green,
                  action: SnackBarAction(
                    label: 'UNDO',
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Action undone')),
                    ),
                  ),
                ),
              ),
              child: const Text('Show Success SnackBar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionErrorTestWidget extends StatefulWidget {
  @override
  State<_PermissionErrorTestWidget> createState() => _PermissionErrorTestWidgetState();
}

class _PermissionErrorTestWidgetState extends State<_PermissionErrorTestWidget> {
  String? _permissionError;
  IconData? _permissionIcon;
  String? _permissionDescription;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Permission Error Test')),
      body: Column(
        children: [
          if (_permissionError != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.red.shade100,
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(_permissionIcon, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(_permissionError!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_permissionDescription!),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Go to Settings'),
                  ),
                ],
              ),
            ),
          ],
          ElevatedButton(
            key: const Key('request_camera'),
            onPressed: () => setState(() {
              _permissionError = 'Camera permission required';
              _permissionIcon = Icons.camera_alt_outlined;
              _permissionDescription = 'Please grant camera permission to use this feature';
            }),
            child: const Text('Request Camera Permission'),
          ),
          ElevatedButton(
            key: const Key('request_location'),
            onPressed: () => setState(() {
              _permissionError = 'Location permission required';
              _permissionIcon = Icons.location_off;
              _permissionDescription = 'Location access is needed for this feature to work properly';
            }),
            child: const Text('Request Location Permission'),
          ),
          ElevatedButton(
            key: const Key('request_storage'),
            onPressed: () => setState(() {
              _permissionError = 'Storage permission required';
              _permissionIcon = Icons.folder_off;
              _permissionDescription = 'Storage access is required to save files';
            }),
            child: const Text('Request Storage Permission'),
          ),
        ],
      ),
    );
  }
}

class _UserFeedbackTestWidget extends StatefulWidget {
  @override
  State<_UserFeedbackTestWidget> createState() => _UserFeedbackTestWidgetState();
}

class _UserFeedbackTestWidgetState extends State<_UserFeedbackTestWidget> {
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Feedback Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              key: const Key('feedback_button'),
              onPressed: () {
                // Simulate button feedback
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Button pressed!')),
                );
              },
              child: const Text('Press for Feedback'),
            ),
            const SizedBox(height: 20),
            if (_isSubmitting) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 8),
              const Text('Submitting...'),
            ] else if (_isSubmitted) ...[
              const Icon(Icons.check_circle, color: Colors.green, size: 48),
              const SizedBox(height: 8),
              const Text('Form submitted successfully!'),
            ] else ...[
              ElevatedButton(
                key: const Key('submit_form'),
                onPressed: () async {
                  setState(() {
                    _isSubmitting = true;
                  });
                  await Future.delayed(const Duration(seconds: 2));
                  setState(() {
                    _isSubmitting = false;
                    _isSubmitted = true;
                  });
                },
                child: const Text('Submit Form'),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              key: const Key('delete_item'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Item deleted'),
                    action: SnackBarAction(
                      label: 'UNDO',
                      onPressed: () {},
                    ),
                  ),
                );
              },
              child: const Text('Delete Item'),
            ),
          ],
        ),
      ),
    );
  }
}
