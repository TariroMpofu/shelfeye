import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// On-device diagnostics log for field support. [install] wraps `debugPrint` so
/// every log line (API requests/responses, ping, licence, currency, etc.) is
/// captured. Lines are kept in memory AND appended to a daily file so they
/// survive app restarts/crashes; files older than 7 days are pruned.
///
/// No credentials are logged anywhere (the API client logs URIs + bodies, never
/// the UserName/Password headers), so the log is safe to share.
class LogBuffer {
  static final List<String> _mem = <String>[];
  static final List<String> _pending = <String>[];
  static const int _maxMem = 3000;
  static const int _keepDays = 7;

  static Directory? _dir;
  static DebugPrintCallback? _original;
  static bool _installed = false;

  /// Redirect debugPrint through the buffer + start the daily file. Call once in
  /// main(). Safe to await (sets up the log directory).
  static Future<void> install() async {
    if (_installed) return;
    _installed = true;
    _original = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) _append(message);
      _original?.call(message, wrapWidth: wrapWidth);
    };
    try {
      final base = await getApplicationDocumentsDirectory();
      _dir = Directory('${base.path}/logs');
      if (!_dir!.existsSync()) _dir!.createSync(recursive: true);
      await _prune();
    } catch (_) {
      _dir = null;
    }
    // Batch writes so we don't hit disk on every line (runs for the app's life).
    Timer.periodic(const Duration(seconds: 3), (_) => _flush());
  }

  /// Add a tagged line directly (e.g. LogBuffer.log('LICENCE', 'paused')).
  static void log(String tag, String message) => _append('[$tag] $message');

  static void _append(String message) {
    final line = '${DateTime.now().toIso8601String()}  $message';
    _mem.add(line);
    _pending.add(line);
    if (_mem.length > _maxMem) _mem.removeRange(0, _mem.length - _maxMem);
  }

  static String _todayName() {
    final d = DateTime.now();
    return 'log-${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}.txt';
  }

  static Future<void> _flush() async {
    if (_dir == null || _pending.isEmpty) return;
    final chunk = _pending.join('\n');
    _pending.clear();
    try {
      final f = File('${_dir!.path}/${_todayName()}');
      await f.writeAsString('$chunk\n', mode: FileMode.append, flush: true);
    } catch (_) {}
  }

  /// Delete daily files older than [_keepDays].
  static Future<void> _prune() async {
    final dir = _dir;
    if (dir == null) return;
    final cutoff = DateTime.now().subtract(const Duration(days: _keepDays));
    try {
      for (final e in dir.listSync()) {
        if (e is! File || !e.path.contains('log-')) continue;
        final m = RegExp(r'log-(\d{4})-(\d{2})-(\d{2})\.txt')
            .firstMatch(e.uri.pathSegments.last);
        if (m == null) continue;
        final d = DateTime(
            int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!));
        if (d.isBefore(DateTime(cutoff.year, cutoff.month, cutoff.day))) {
          try {
            e.deleteSync();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  static int get length => _mem.length;

  /// Build one file with the last 7 days of logs, ready to share.
  static Future<File> buildCombinedFile() async {
    await _flush();
    final b = StringBuffer()
      ..writeln('PriceCheck (ShelfLine) — diagnostics log')
      ..writeln('Generated: ${DateTime.now().toIso8601String()}')
      ..writeln('Retention: last $_keepDays days')
      ..writeln('==========================================');

    final dir = _dir;
    if (dir != null) {
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.uri.pathSegments.last.startsWith('log-'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      for (final f in files) {
        b.writeln();
        b.writeln('────── ${f.uri.pathSegments.last} ──────');
        try {
          b.writeln(await f.readAsString());
        } catch (_) {}
      }
    } else {
      // No file storage — fall back to the in-memory session.
      for (final l in _mem) {
        b.writeln(l);
      }
    }

    final outDir = dir ?? await getTemporaryDirectory();
    final out = File('${outDir.path}/pricecheck-logs.txt');
    await out.writeAsString(b.toString(), flush: true);
    return out;
  }
}
