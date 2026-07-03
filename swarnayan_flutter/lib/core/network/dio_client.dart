import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import 'api_endpoints.dart';
import 'api_exception.dart';

class DioClient {
  static final DioClient instance = DioClient._();
  
  final Dio _dio;

  DioClient._() : _dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      contentType: Headers.jsonContentType,
    ),
  ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          final apiException = ApiException.fromDioError(e);
          
          // NOTE: Do NOT clear credentials on 401 here.
          // The auth provider and router guard handle the auth lifecycle.
          // Clearing here causes race conditions where pre-login 401 responses
          // wipe the token that was just saved by a successful login.
          
          return handler.next(
            DioException(
              requestOptions: e.requestOptions,
              response: e.response,
              type: e.type,
              error: apiException,
              message: apiException.message,
            ),
          );
        },
      ),
    );
  }

  Dio get dio => _dio;
}

