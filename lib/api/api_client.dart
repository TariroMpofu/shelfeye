import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/app_config.dart';
import 'api_exception.dart';

/// Outcome of a reachability ping.
class PingResult {
  final bool ok;
  final String? errorMessage;
  const PingResult.ok()
      : ok = true,
        errorMessage = null;
  const PingResult.fail(this.errorMessage) : ok = false;
}

/// The ONLY place HTTP lives. Builds URIs (percent-encoding query params),
/// sends auth headers, applies timeouts, and converts non-2xx into
/// [ApiException] with a mapped [friendlyHttpMessage]. Everything above the
/// repository depends on this, never on `http` directly.
class ApiClient {
  final AppConfig config;

  /// One reused connection (keep-alive) for every request, so we don't pay a
  /// fresh TCP/TLS handshake per call. Closed via [dispose] when the client is
  /// rebuilt.
  final http.Client _client = http.Client();

  ApiClient(this.config);

  void dispose() => _client.close();

  Map<String, String> get _headers => {
        'UserName': config.apiUserId,
        'Password': config.apiPassword,
        'Accept': 'application/json',
      };

  Uri _uri(String endpoint, [Map<String, String>? q]) {
    var base = config.apiBaseUrl.trim();
    if (base.isEmpty) throw ApiException('Server is not configured');
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final uri = Uri.parse('$base$path');
    return (q == null || q.isEmpty)
        ? uri
        : uri.replace(queryParameters: {...uri.queryParameters, ...q});
  }

  Future<dynamic> getJson(
    String endpoint, {
    Map<String, String>? query,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final uri = _uri(endpoint, query);
    debugPrint('▶ GET $uri');
    http.Response res;
    try {
      res = await _client.get(uri, headers: _headers).timeout(timeout);
    } catch (e) {
      debugPrint('◀ GET failed: $e');
      // Friendly mapping (timeout / can't reach server) like StockRoom, so the
      // operator-readable userMessage surfaces in Settings and on lookup errors.
      throw ApiException('Network error: $e',
          friendlyMessage: humanizeNetworkError(e));
    }
    final ok = res.statusCode >= 200 && res.statusCode < 300;
    debugPrint('◀ ${res.statusCode} ${logBody(res.body)}');
    if (!ok) {
      throw ApiException('HTTP ${res.statusCode}: ${res.body}',
          statusCode: res.statusCode,
          friendlyMessage: friendlyHttpMessage(res.statusCode, res.body));
    }
    if (res.body.trim().isEmpty) return null;
    try {
      return jsonDecode(res.body);
    } catch (_) {
      return res.body;
    }
  }

  /// Adaptive timeout: short when warm, long for a cold IIS pool.
  Future<PingResult> ping({Duration timeout = const Duration(seconds: 30)}) async {
    try {
      final uri = _uri('/CheckAPIConnection/');
      final res = await _client.get(uri, headers: _headers).timeout(timeout);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return const PingResult.ok();
      }
      return PingResult.fail(friendlyHttpMessage(res.statusCode, res.body));
    } catch (e) {
      return PingResult.fail(humanizeNetworkError(e));
    }
  }
}
