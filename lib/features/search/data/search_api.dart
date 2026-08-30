import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../domain/shloka_result.dart';

class SearchUnavailableException implements Exception {
  const SearchUnavailableException();
}

/// hasMore tells the caller whether it's worth asking for the next page —
/// page *size* is never something this client controls, only which page.
class SearchPage {
  const SearchPage({required this.results, required this.hasMore});

  final List<ShlokaResult> results;
  final bool hasMore;
}

abstract class SearchApi {
  Future<SearchPage> search(String query, {int page = 0});
}

class DioSearchApi implements SearchApi {
  DioSearchApi(this._dio);

  final Dio _dio;

  @override
  Future<SearchPage> search(String query, {int page = 0}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/search',
        queryParameters: {'q': query, 'page': page},
      );
      final results = response.data?['results'] as List? ?? const [];
      return SearchPage(
        results: results
            .map((r) => ShlokaResult.fromJson(r as Map<String, dynamic>))
            .toList(),
        hasMore: response.data?['has_more'] as bool? ?? false,
      );
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
