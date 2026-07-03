import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});

  factory ApiException.fromDioError(DioException dioError) {
    String message = 'Something went wrong. Please try again.';
    int? statusCode = dioError.response?.statusCode;

    if (dioError.type == DioExceptionType.connectionTimeout ||
        dioError.type == DioExceptionType.receiveTimeout ||
        dioError.type == DioExceptionType.sendTimeout) {
      message = 'Connection timed out. Please check your network connection.';
    } else if (dioError.type == DioExceptionType.connectionError) {
      message = 'No internet connection. Please verify your active connection.';
    } else if (dioError.response != null) {
      final responseData = dioError.response?.data;
      if (responseData is Map<String, dynamic> && responseData.containsKey('message')) {
        message = responseData['message'] ?? message;
      } else {
        switch (statusCode) {
          case 400:
            message = 'Bad request. Please verify inputs.';
            break;
          case 401:
            message = 'Unauthorized. Session expired. Please log in again.';
            break;
          case 403:
            message = 'Access denied. You do not have permission to do this.';
            break;
          case 404:
            message = 'Resource not found.';
            break;
          case 500:
            message = 'Server error. Please try again later.';
            break;
        }
      }
    }
    
    return ApiException(message: message, statusCode: statusCode);
  }

  @override
  String toString() => message;
}
