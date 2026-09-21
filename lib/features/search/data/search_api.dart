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

  // One initial attempt plus two retries. The delays are short on purpose —
  // this is masking a blip during a single user-initiated request, not
  // waiting out an outage; if it's still failing after ~1.3s of retrying,
  // more retrying isn't going to help and the UI should hear about it.
  static const _maxAttempts = 3;
  static const _retryDelays = [
    Duration(milliseconds: 400),
    Duration(milliseconds: 900),
  ];

  @override
  Future<SearchPage> search(String query, {int page = 0}) async {
    for (var attempt = 1; ; attempt++) {
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
        final willRetry = attempt < _maxAttempts && _isTransient(error);
        developer.log(
          willRetry ? 'Shloka search failed, retrying' : 'Shloka search failed',
          error: error,
          stackTrace: stackTrace,
          name: 'SearchApi',
        );
        if (!willRetry) throw const SearchUnavailableException();
        await Future.delayed(_retryDelays[attempt - 1]);
      }
    }
  }

  /// A timeout or the server's own 5xx is usually a passing blip — the same
  /// request tried again a moment later often just works. A 4xx means the
  /// request itself was bad, so retrying it unchanged will only fail the
  /// same way again. connectionError (no network reachable at all, e.g.
  /// wifi off) also isn't retried here — that's not going to resolve
  /// itself within a couple of seconds, so failing fast into the error
  /// state is more honest than a doomed retry loop.
  static bool _isTransient(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return true;
      case DioExceptionType.badResponse:
        return (error.response?.statusCode ?? 0) >= 500;
      default:
        return false;
    }
  }
}
