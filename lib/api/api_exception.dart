import 'dart:convert';

/// Transport/HTTP error carrying an operator-readable message.
/// `friendlyMessage` is produced by [friendlyHttpMessage]; `userMessage`
/// prefers it over the raw message. Ported from StockRoom.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? friendlyMessage;

  ApiException(this.message, {this.statusCode, this.friendlyMessage});

  String get userMessage => friendlyMessage ?? message;

  @override
  String toString() => message;
}

/// Collapses a body to one short line for logging.
String shortBody(String s, [int max = 220]) {
  final oneLine = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (oneLine.isEmpty) return '(empty body — no match found)';
  if (oneLine.length <= max) return oneLine;
  return '${oneLine.substring(0, max)}… (+${oneLine.length - max} chars)';
}

/// Full response body for the diagnostics log — real data (prices, IDs, store
/// details) is kept in full, but the always-empty iVend WCF envelope fields
/// that repeat on every object are stripped so the log stays scannable. The
/// giant product-image base64 is replaced with a placeholder.
String logBody(String s) {
  var t = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (t.isEmpty) return '(empty body — no match found)';
  t = t.replaceAll(
    RegExp(r'"ImageBase64String"\s*:\s*"[^"]*"'),
    '"ImageBase64String":"[image omitted]"',
  );
  // Drop the boilerplate envelope keys iVend stamps on every record. These are
  // always empty/false/null and otherwise dominate each line.
  for (final noise in const [
    '"Message":"",',
    '"GenerateIntegrationEvent":false,',
    '"EnterpriseName":"",',
    '"UserFieldsList":null,',
  ]) {
    t = t.replaceAll(noise, '');
  }
  return t;
}

/// Detects iVend's database-failure payload (SQL Server down → HTTP 400 with a
/// CXSDataException whose Message is developer NHibernate text).
String? _detectDatabaseFailure(String body) {
  final t = body.trim();
  if (!t.startsWith('{')) return null;
  try {
    final d = jsonDecode(t);
    if (d is! Map<String, dynamic>) return null;
    final type = d['ExceptionType']?.toString() ?? '';
    final desc = d['Description']?.toString() ?? '';
    if (type.contains('CXSDataException') ||
        desc.contains('SqlException') ||
        desc.contains('SQL Server') ||
        desc.contains('GenericADOException')) {
      return 'iVend server cannot reach its database (SQL Server error). '
          'Check that the SQL Server service is running on the server, '
          'then try again.';
    }
  } catch (_) {}
  return null;
}

/// Pulls a readable message out of an iVend JSON error body (null for HTML).
String? _extractApiMessage(String body) {
  final t = body.trim();
  if (t.isEmpty || t.startsWith('<')) return null;
  try {
    final d = jsonDecode(t);
    if (d is Map<String, dynamic>) {
      for (final k in const [
        'Message',
        'message',
        'Error',
        'error',
        'ErrorMessage',
        'ErrorDescription',
      ]) {
        final v = d[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
    }
  } catch (_) {}
  return t.length > 200 ? '${t.substring(0, 200)}…' : t;
}

({int code, int? sub, String description})? _parseIisErrorPage(String body) {
  if (!body.trimLeft().startsWith('<')) return null;
  final m = RegExp(
    r'<title>\s*(\d{3})(?:\.(\d+))?\s*-\s*([^<]+)</title>',
    caseSensitive: false,
  ).firstMatch(body);
  if (m == null) return null;
  return (
    code: int.parse(m.group(1)!),
    sub: m.group(2) == null ? null : int.tryParse(m.group(2)!),
    description: m.group(3)!.trim(),
  );
}

/// Maps a non-2xx response to operator/technician-readable guidance.
/// Priority: SQL-down → iVend JSON message → IIS page (by substatus) → 503 →
/// bare status. Ported from StockRoom.
String friendlyHttpMessage(int statusCode, String body) {
  final db = _detectDatabaseFailure(body);
  if (db != null) return db;
  final apiMsg = _extractApiMessage(body);
  if (apiMsg != null) return apiMsg;

  final iis = _parseIisErrorPage(body);
  final sub = iis?.sub;
  final tag = sub != null ? 'IIS $statusCode.$sub' : 'HTTP $statusCode';

  switch (statusCode) {
    case 401:
      return 'The web server refused access ($tag). Check the API user and '
          'password, and that Anonymous Authentication is enabled for the '
          'iVendAPI site in IIS.';
    case 403:
      return switch (sub) {
        6 => "This device's IP address is blocked by the server ($tag).",
        11 =>
          'The server reports the password has changed ($tag). '
              'Re-enter the API password.',
        _ => 'Access denied by the server ($tag).',
      };
    case 404:
      return switch (sub) {
        3 || 4 =>
          'The server does not recognise the API request ($tag). '
              'Re-register WCF/ASP.NET handler mappings for iVendAPI.',
        _ =>
          'iVend API not found at this address ($tag). Check the host IP '
              'and that the iVend API is installed.',
      };
    case 413:
      return 'Request too large for the server ($tag).';
    case 500:
      return switch (sub) {
        13 => 'iVend server is too busy right now ($tag). Try again shortly.',
        19 => 'Invalid server configuration for iVendAPI ($tag).',
        _ =>
          'iVend server internal error ($tag). Check the iVend API service '
              'and SQL Server, then the server event logs.',
      };
    case 503:
      return 'iVend server is unavailable (503). The application pool may be '
          'stopped or recycling — check the iVend API service.';
    default:
      if (iis != null) return '${iis.description} ($tag)';
      return 'Server error (HTTP $statusCode).';
  }
}

String humanizeNetworkError(Object e) {
  final s = e.toString();
  if (s.contains('TimeoutException')) {
    return "Server didn't respond in time. Check the host or network.";
  }
  if (s.contains('SocketException') || s.contains('Failed host lookup')) {
    return "Can't reach the server. Check the IP address and Wi-Fi.";
  }
  return s;
}
