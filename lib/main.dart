import 'package:flutter/material.dart';
import 'welcome.dart';
import 'app_theme.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    home: WelcomeScreen(),
  ));
}