import 'package:dio/dio.dart';

class ErrorHandler {
  static String getMessage(dynamic error) {
    if (error is DioException) {
      // Extract message from response body (backend sends error.message)
      if (error.response?.data is Map && error.response?.data['message'] != null) {
        return error.response?.data['message'];
      }
      
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return "Connection timed out. Please check your internet.";
        case DioExceptionType.connectionError:
          return "No internet connection.";
        case DioExceptionType.badResponse:
          final status = error.response?.statusCode;
          if (status == 400) return error.response?.data['message'] ?? "Invalid request.";
          if (status == 401) return "Unauthorized. Please login again.";
          if (status == 403) return error.response?.data['message'] ?? "Access denied.";
          if (status == 404) return error.response?.data['message'] ?? "Resource not found.";
          if (status == 500) return "Internal server error. Please try again later.";
          return "Server returned an error: $status";
        default:
          return "Something went wrong. Please try again.";
      }
    }
    return error.toString();
  }
}
