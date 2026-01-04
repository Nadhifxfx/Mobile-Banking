import 'package:flutter/material.dart';

/// API Configuration and Constants
class ApiConstants {
  // Base URLs
  static const String middlewareBaseUrl = 'http://localhost:8000/api/v1';
  static const String serviceLayerBaseUrl = 'http://localhost:8001/service';
  
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

/// App Colors
class AppColors {
  static const primaryBlue = Color(0xFF1976D2);
  static const darkBlue = Color(0xFF0D47A1);
  static const lightBlue = Color(0xFF64B5F6);
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFC107);
  static const error = Color(0xFFE53935);
  static const grey = Color(0xFF757575);
  static const lightGrey = Color(0xFFE0E0E0);
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
