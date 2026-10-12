import 'package:flutter/material.dart';

class AppColors {
  static const Color orange = Color(0xFFF57C00);
  static const Color orangeSoft = Color(0xFFFFF4E6);
  static const Color navy = Color(0xFF1B2A41);
  static const Color cream = Color(0xFFF7F4EE);
  static const Color green = Color(0xFF2E7D32);
  static const Color greenSoft = Color(0xFFE8F5E9);
  static const Color red = Color(0xFFD32F2F);
  static const Color redSoft = Color(0xFFFEF1F1);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
}

class AppStrings {
  static const String appName = 'Easymart';
  static const String tagline = 'Easy Shop, Smart Choice.';
  static const String customerDemoEmail = 'user@easymart.com';
  static const String customerDemoPassword = 'User123!';
  static const String adminDemoEmail = 'admin@easymart.com';
  static const String adminDemoPassword = 'Admin123!';
}

class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String adminDashboard = '/admin';
}

class AppOrderStatuses {
  static const List<String> values = [
    'Order Placed',
    'Order Confirmed',
    'Preparing Your Groceries',
    'Ready for Delivery',
    'Out for Delivery',
    'Delivered',
    'Cancelled',
  ];
}
