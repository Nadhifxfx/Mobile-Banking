import 'package:flutter/material.dart';

/// API Configuration and Constants
class ApiConstants {
  // Base URLs
  static const String defaultMiddlewareBaseUrl = 'http://localhost:8000/api/v1';
  static const String defaultServiceLayerBaseUrl = 'http://localhost:8001/service';

  @Deprecated('Use AppSettings.getMiddlewareBaseUrl() for runtime-configurable server host')
  static const String middlewareBaseUrl = defaultMiddlewareBaseUrl;

  @Deprecated('Use AppSettings.getServiceLayerBaseUrl() for runtime-configurable server host')
  static const String serviceLayerBaseUrl = defaultServiceLayerBaseUrl;
  
  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String accountsEndpoint = '/account';
  static const String transactionsEndpoint = '/transaction';
  static const String transferEndpoint = '/transaction/transfer';
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Storage Keys
  static const String tokenKey = 'jwt_token';
  static const String userIdKey = 'user_id';
  static const String usernameKey = 'username';
  static const String isLoggedInKey = 'is_logged_in';
}

/// App Colors - BRImo Inspired Professional Design
class AppColors {
  // Primary BRI Blue gradient colors
  static const primaryBlue = Color(0xFF003D7A);
  static const secondaryBlue = Color(0xFF0066CC);
  static const lightBlue = Color(0xFF4A90E2);
  static const accentBlue = Color(0xFF2196F3);
  
  // Accent colors
  static const briOrange = Color(0xFFFF6B35);
  static const success = Color(0xFF00BFA5);
  static const warning = Color(0xFFFFA726);
  static const error = Color(0xFFEF5350);
  
  // Neutral colors
  static const darkGrey = Color(0xFF37474F);
  static const grey = Color(0xFF757575);
  static const lightGrey = Color(0xFFE0E0E0);
  static const backgroundGrey = Color(0xFFF5F6FA);
  static const white = Color(0xFFFFFFFF);
  
  // Gradient
  static const gradientStart = primaryBlue;
  static const gradientEnd = secondaryBlue;
  
  // Transaction colors
  static const incomeGreen = Color(0xFF00C853);
  static const expenseRed = Color(0xFFD32F2F);
}

/// Transaction Types
class TransactionType {
  static const String transfer = 'TR';
  static const String withdraw = 'WD';
  static const String deposit = 'DP';
}

/// Transaction Status
class TransactionStatus {
  static const String success = 'SUCCESS';
  static const String pending = 'PENDING';
  static const String failed = 'FAILED';
}
