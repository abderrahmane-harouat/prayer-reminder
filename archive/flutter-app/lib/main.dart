import 'package:athan_app_v2/screens/main_shell.dart';
import 'package:athan_app_v2/services/connectivity_service.dart';
import 'package:athan_app_v2/services/prayer_notitfication_service.dart';
import 'package:athan_app_v2/services/settings_notifier.dart';
import 'package:athan_app_v2/services/storage_service.dart';
import 'package:athan_app_v2/theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Brightness;
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for Arabic locale
  await initializeDateFormatting('ar', null);

  await PrayerNotificationService.initialize();
  await StorageService().initialize();
  await ConnectivityService().initialize();
  await settingsNotifier.loadSettings();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Skill: jetpack-compose-ui — edge-to-edge: draw behind system bars.
  // SafeArea on every screen below acts as
  // Modifier.windowInsetsPadding(WindowInsets.safeDrawing).
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'مواقيت الصلاة',
      theme: CupertinoThemeData(
        brightness: MediaQuery.platformBrightnessOf(context),
        primaryColor: CupertinoColors.systemBlue,
        barBackgroundColor: CupertinoColors.systemBackground,
        scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(
            fontFamily: AppConstants.fontFamily,
            fontWeight: FontWeight.w400,
            fontSize: 18.0,
            height: 1.5,
            decoration: TextDecoration.none,
          ),
          actionTextStyle: TextStyle(
            fontFamily: AppConstants.fontFamily,
            fontWeight: FontWeight.w400,
            fontSize: 20.0,
            height: 1.4,
            color: CupertinoColors.systemBlue,
            decoration: TextDecoration.none,
          ),
          navTitleTextStyle: TextStyle(
            fontFamily: AppConstants.fontFamily,
            fontWeight: FontWeight.w400,
            fontSize: 22.0,
            height: 1.35,
            decoration: TextDecoration.none,
          ),
          navLargeTitleTextStyle: TextStyle(
            fontFamily: AppConstants.fontFamily,
            fontWeight: FontWeight.w300,
            fontSize: 36.0,
            height: 1.25,
            letterSpacing: -0.25,
            decoration: TextDecoration.none,
          ),
        ),
      ),
      home: MainShell(),
      locale: Locale('ar', 'DZ'),
    );
  }
}
