import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadhana/features/search/data/search_api.dart';

/// A scripted HttpClientAdapter: each call to fetch() consumes the next
/// entry in [responses] — either a status code to respond with, or a
/// DioExceptionType to fail with — so a test can simulate "times out, then
/// succeeds" or "fails every time" without a real network call.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.responses);

  final List<Object> responses;
  int callCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final response = responses[callCount];
    callCount++;
    if (response is DioExceptionType) {
      throw DioException(requestOptions: options, type: response);
    }
    final body = utf8.encode('{"results": [], "has_more": false}');
    return ResponseBody.fromBytes(
      body,
      response as int,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

DioSearchApi _apiWithScript(List<Object> responses) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test'))
    ..httpClientAdapter = _ScriptedAdapter(responses);
  return DioSearchApi(dio);
}

void main() {
  test('retries a timeout and succeeds on the next attempt', () async {
    final api = _apiWithScript([DioExceptionType.connectionTimeout, 200]);

    final page = await api.search('gayatri');

    expect(page.results, isEmpty);
  });

  test('retries a 502 and succeeds on the next attempt', () async {
    final api = _apiWithScript([502, 200]);

    final page = await api.search('gayatri');

    expect(page.results, isEmpty);
  });

  test('gives up after exhausting retries on repeated timeouts', () async {
    final adapter = _ScriptedAdapter([
      DioExceptionType.connectionTimeout,
      DioExceptionType.connectionTimeout,
      DioExceptionType.connectionTimeout,
    ]);
    final dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..httpClientAdapter = adapter;
    final api = DioSearchApi(dio);

    await expectLater(
      () => api.search('gayatri'),
      throwsA(isA<SearchUnavailableException>()),
    );
    // Exactly maxAttempts (3) calls — not retried forever.
    expect(adapter.callCount, 3);
  });

  test('does not retry a 400 — the request itself was bad', () async {
    final adapter = _ScriptedAdapter([400, 200]);
    final dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..httpClientAdapter = adapter;
    final api = DioSearchApi(dio);

    await expectLater(
      () => api.search('gayatri'),
      throwsA(isA<SearchUnavailableException>()),
    );
    // Only the one call — a second (the scripted "200") was never made.
    expect(adapter.callCount, 1);
  });

  test('does not retry a connection error (no network reachable)', () async {
    final adapter = _ScriptedAdapter([DioExceptionType.connectionError, 200]);
    final dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..httpClientAdapter = adapter;
    final api = DioSearchApi(dio);

    await expectLater(
      () => api.search('gayatri'),
      throwsA(isA<SearchUnavailableException>()),
    );
    expect(adapter.callCount, 1);
  });
}
