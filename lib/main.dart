import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/providers/apk_provider.dart';
import 'core/providers/app_provider.dart';
import 'core/theme.dart';
import 'features/splash/splash_screen.dart';
import 'firebase_options.dart';
import 'utils/helpers.dart';
import 'utils/notification_helper.dart';
import 'services/download_service.dart';

/// Application entry point
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations (portrait only)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    logger.i('Firebase initialized successfully');
  } catch (e) {
    // Log error and continue
    logger.e('Firebase initialization error: $e');
    // In production, you might want to handle this differently
  }
  
  // Initialize notifications
  try {
    await NotificationHelper.initialize();
    logger.i('Notifications initialized successfully');
  } catch (e) {
    logger.e('Notification initialization error: $e');
  }
  
  runApp(const APKUploaderApp());
}

/// The main app widget
class APKUploaderApp extends StatefulWidget {
  /// Constructor
  const APKUploaderApp({super.key});

  @override
  State<APKUploaderApp> createState() => _APKUploaderAppState();
}

class _APKUploaderAppState extends State<APKUploaderApp> with WidgetsBindingObserver {
  final DownloadService _downloadService = DownloadService();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Register for lifecycle events
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Unregister from lifecycle events
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the app resumes, check for pending installations
    if (state == AppLifecycleState.resumed) {
      _checkPendingInstallations();
    }
  }

  // Check for any pending installations when the app resumes
  Future<void> _checkPendingInstallations() async {
    try {
      // Get current context from navigator
      final context = _navigatorKey.currentContext;
      if (context != null) {
        // Check and resume any pending installations
        final resumed = await _downloadService.checkAndResumeInstallation(context);
        if (resumed) {
          logger.i('Successfully resumed pending installation');
        }
      }
    } catch (e) {
      logger.e('Error checking pending installations: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppProvider()),
        ChangeNotifierProvider(create: (context) => APKProvider()),
      ],
      child: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          final isDarkMode = appProvider.isDarkMode;
          
          return MaterialApp(
            title: 'APK Uploader',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
            debugShowCheckedModeBanner: false, // No debug banner in production
            navigatorKey: _navigatorKey, // Set navigator key for context access
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
