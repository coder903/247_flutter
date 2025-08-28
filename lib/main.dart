// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/themes.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/auth_service.dart';
import 'services/camera_service.dart';
import 'services/sync_manager.dart';
import 'database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize cameras
    await CameraService.initCameras();
    print('Cameras initialized successfully');
  } catch (e) {
    print('Failed to initialize cameras: $e');
    // App can still run without camera
  }
  
  try {
    // Initialize database
    await DatabaseHelper.instance.database;
    print('Database initialized successfully');
  } catch (e) {
    print('Failed to initialize database: $e');
    // This is critical - rethrow
    rethrow;
  }
  
  try {
    // Initialize sync manager
    await SyncManager.instance.initialize();
    print('Sync manager initialized successfully');
    
    // Perform initial sync when app starts
    SyncManager.instance.syncNow().then((_) {
      print('Initial sync completed');
    }).catchError((error) {
      print('Initial sync error: $error');
      // App can still function in offline mode
    });
  } catch (e) {
    print('Failed to initialize sync manager: $e');
    // App can still run in offline mode
  }
  
  runApp(const FireInspectionApp());
}

class FireInspectionApp extends StatelessWidget {
  const FireInspectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'Fire Inspection',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
        // Define routes
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
        },
        // Handle unknown routes
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          );
        },
      ),
    );
  }
}

// Auth wrapper to handle initialization
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.loadStoredAuth();
    
    // If user is authenticated, trigger a sync
    if (authService.isAuthenticated) {
      SyncManager.instance.syncNow().then((_) {
        print('Post-authentication sync completed');
      }).catchError((error) {
        print('Post-authentication sync error: $error');
      });
    }
    
    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Consumer<AuthService>(
      builder: (context, authService, _) {
        if (authService.isAuthenticated) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

// Override error widget for production
class MyErrorWidget extends StatelessWidget {
  final FlutterErrorDetails errorDetails;

  const MyErrorWidget({
    Key? key,
    required this.errorDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                'Oops! Something went wrong',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                errorDetails.exception.toString(),
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Navigate to home or login
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                child: const Text('Restart App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// In your main() function, add custom error handling for production
void setupErrorHandling() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Log to crash reporting service
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MyErrorWidget(errorDetails: details);
  };
}