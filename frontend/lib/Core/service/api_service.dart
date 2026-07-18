import "package:dio/dio.dart";
import "package:flutter/widgets.dart";

import "api_exceptions.dart";

/// Generic API service that handles CRUD operations for any type [T].
///
/// [T] is your model (e.g. User, Product). You provide a [fromJson]
/// converter so this class can deserialize responses regardless of
/// what endpoint/model it's talking to.
///
/// This class does NOT know about auth, retries, or logging — that's
/// already handled centrally by the interceptors on the shared [Dio]
/// instance (see dio_client_provider.dart). This class only cares
/// about shaping requests/responses and translating errors.
class ApiService<T> {
  final Dio _dio;
  final T Function(Map<String, dynamic> json) fromJson;

  ApiService({required Dio dio, required this.fromJson}) : _dio = dio;

  /// GET a list of resources.
  /// e.g. getAll(endpoint: "/users", queryParams: {"page": 1})
  Future<List<T>> getAll({
    required String endpoint,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      final data = response.data;
      if (data is! List) {
        throw ParsingException("Expected a list response from $endpoint");
      }

      final data0 = data
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();
      debugPrint("APIService.getAll: endpoint=$endpoint, data=$data0");

      for (final item in data) {
        debugPrint("RAW ITEM: $item");
      }

      debugPrint("Parsed ${data0.length} items");
      return data0;
    } on DioException catch (e) {
      throw mapDioExceptionToApiException(e);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ParsingException("Failed to parse list response: $e");
    }
  }

  /// GET a single resource by id.
  /// e.g. getById(endpoint: "/users", id: "42")
  Future<T> getById({
    required String endpoint,
    required String id,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.get(
        "$endpoint/$id",
        queryParameters: queryParams,
        options: Options(headers: headers),
      );
      return _parseSingle(response.data, endpoint);
    } on DioException catch (e) {
      throw mapDioExceptionToApiException(e);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ParsingException("Failed to parse response: $e");
    }
  }

  /// POST a new resource.
  /// e.g. create(endpoint: "/users", data: newUser.toJson())
  Future<T> create({
    required String endpoint,
    required Map<String, dynamic> data,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    debugPrint("Sending CREATE API ...");
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );
      final data0 = response.data as Map<String, dynamic>;
      debugPrint(response.data.toString());
      debugPrint(response.data.runtimeType.toString());
      debugPrint('===== RESPONSE TYPES =====');
      data0.forEach((key, value) {
        debugPrint('$key -> ${value.runtimeType} : $value');
      });
      debugPrint('==========================');

      debugPrint("From service (CREATE) Response.Data: ${response.data}");
      return _parseSingle(response.data, endpoint);
    } on DioException catch (e) {
      debugPrint("From service Layer (Create FUNCTION): $e");
      debugPrint("Status: ${e.response?.statusCode}");
      debugPrint("Body: ${e.response?.data}");
      throw mapDioExceptionToApiException(e);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ParsingException("Failed to parse response: $e");
    }
  }

  /// PUT — full update/replace of a resource.
  /// e.g. update(endpoint: "/users", id: "42", data: user.toJson())
  Future<T> update({
    required String endpoint,
    required String id,
    required Map<String, dynamic> data,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.put(
        "$endpoint/$id",
        data: data,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );
      return _parseSingle(response.data, endpoint);
    } on DioException catch (e) {
      throw mapDioExceptionToApiException(e);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ParsingException("Failed to parse response: $e");
    }
  }

  /// PATCH — partial update of a resource.
  /// e.g. patch(endpoint: "/users", id: "42", data: {"name": "New Name"})
  Future<T> patch({
    required String endpoint,
    required String id,
    required Map<String, dynamic> data,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.patch(
        "$endpoint/$id",
        data: data,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );
      return _parseSingle(response.data, endpoint);
    } on DioException catch (e) {
      throw mapDioExceptionToApiException(e);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ParsingException("Failed to parse response: $e");
    }
  }

  /// DELETE a resource by id.
  /// e.g. delete(endpoint: "/users", id: "42")
  Future<void> delete({
    required String endpoint,
    required String id,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    try {
      await _dio.delete(
        "$endpoint/$id",
        queryParameters: queryParams,
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      throw mapDioExceptionToApiException(e);
    } on ApiException {
      rethrow;
    }
  }

  //? For APIs which don't have traditional JSON MAP Data
  Future<R> post<R>({
    required String endpoint,
    required Map<String, dynamic> data,
    required R Function(dynamic json) parser,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      return parser(response.data);
    } catch (e) {
      throw mapDioExceptionToApiException(e);
    }
  }

  //? for another non JSON query
  Future<R> get<R>({
    required String endpoint,
    required R Function(dynamic json) parser,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    final response = await _dio.get(
      endpoint,
      queryParameters: queryParams,
      options: Options(headers: headers),
    );

    return parser(response.data);
  }

  /// Shared helper: response body is the raw object itself
  /// (no {"data": {...}} envelope), so we just cast and parse.
  T _parseSingle(dynamic data, String endpoint) {
    if (data is! Map<String, dynamic>) {
      throw ParsingException("Expected an object response from $endpoint");
    }
    return fromJson(data);
  }
}
