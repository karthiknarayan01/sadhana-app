import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../domain/shloka_result.dart';

class SearchUnavailableException implements Exception {
  const SearchUnavailableException();
}

abstract class SearchApi {
  Future<List<ShlokaResult>> search(String query);
}

class DioSearchApi implements SearchApi {
  DioSearchApi(this._dio);

  final Dio _dio;

  @override
  Future<List<ShlokaResult>> search(String query) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/search',
        queryParameters: {'q': query},
      );
      final results = response.data?['results'] as List? ?? const [];
      return results
          .map((r) => ShlokaResult.fromJson(r as Map<String, dynamic>))
          .toList();
    } on DioException catch (error, stackTrace) {
      developer.log(
        'Shloka search failed',
        error: error,
        stackTrace: stackTrace,
        name: 'SearchApi',
      );
      throw const SearchUnavailableException();
    }
  }
}
