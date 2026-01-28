import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:omega_chat/theme/app_theme.dart';
import 'package:omega_chat/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  
  runApp(const OmegaApp());
}

class OmegaApp extends StatelessWidget {
  const OmegaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ne Znayu',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}