import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

/// Thin Dio wrapper. Points at a placeholder base URL for now — swap
/// `baseUrl` when the Node.js/NestJS backend (see master prompt's future
/// migration path) is ready. All calls currently go through mock
/// repositories, so this client is unused until Phase 9.
class DioClient {
  DioClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    // Request and response bodies can contain tokens or personal details.
    // Keep useful diagnostics during development, but never expose them in a
    // release build's device logs.
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }

  static final DioClient instance = DioClient._internal();
  late final Dio _dio;
  Dio get dio => _dio;

  static const String baseUrl = 'https://api.gaz-energiya.uz/v1';
}
