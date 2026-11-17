import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'mcp_tools.dart';

/// MCP over JSON-RPC 2.0: initialize, ping, tools/list, tools/call.
/// Stateless (no sessions, no server-to-client messages), so plain JSON
/// responses over HTTP are enough.
class McpHandler {
  McpHandler(List<McpTool> tools, {this.version = '1.0.0'})
    : _tools = {for (final t in tools) t.name: t};

  final Map<String, McpTool> _tools;
  final String version;

  static const supportedVersions = ['2025-06-18', '2025-03-26', '2024-11-05'];

  static const instructions =
      "Donut is the user's day planner, drawn as a clock. Use these tools to "
      'read and plan their days: entries are time blocks, pins are moments '
      'to plan around. Dates are YYYY-MM-DD and times 24h "HH:MM" in the '
      "user's local wall-clock time. Check get_day or find_free_slots before "
      'adding, and tell the user what you changed. Entries with status '
      '"draft" are plan-mode sketches the user approves with ✓ in Donut.';

  /// Handles one decoded JSON-RPC message or batch. Returns the response
  /// (a map, or a list for a batch), or null when nothing is owed
  /// (notifications only).
  Future<Object?> handle(Object? message) async {
    if (message is List) {
      if (message.isEmpty) return _error(null, -32600, 'Empty batch');
      final out = <Object?>[];
      for (final m in message) {
        final r = await _one(m);
        if (r != null) out.add(r);
      }
      return out.isEmpty ? null : out;
    }
    return _one(message);
  }

  Future<Map<String, Object?>?> _one(Object? m) async {
    if (m is! Map || m['jsonrpc'] != '2.0' || m['method'] is! String) {
      // A response from the client (we never ask it anything): ignore.
      if (m is Map && (m.containsKey('result') || m.containsKey('error'))) {
        return null;
      }
      return _error(m is Map ? m['id'] : null, -32600, 'Invalid request');
    }
    final id = m['id'];
    final isNotification = !m.containsKey('id');
    final method = m['method'] as String;
    final params = m['params'] is Map
        ? (m['params'] as Map).cast<String, Object?>()
        : const <String, Object?>{};
    try {
      final result = await _dispatch(method, params);
      if (isNotification) return null;
      if (result == null) {
        return _error(id, -32601, 'Method not found: $method');
      }
      return {'jsonrpc': '2.0', 'id': id, 'result': result};
    } on _RpcError catch (e) {
      return isNotification ? null : _error(id, e.code, e.message);
    } catch (e, st) {
      debugPrint('MCP: $method failed: $e\n$st');
      return isNotification ? null : _error(id, -32603, 'Internal error: $e');
    }
  }

  Future<Map<String, Object?>?> _dispatch(
    String method,
    Map<String, Object?> params,
  ) async {
    switch (method) {
      case 'initialize':
        final asked = params['protocolVersion'];
        return {
          'protocolVersion': supportedVersions.contains(asked)
              ? asked
              : supportedVersions.first,
          'capabilities': {
            'tools': {'listChanged': false},
          },
          'serverInfo': {'name': 'donut', 'title': 'Donut', 'version': version},
          'instructions': instructions,
        };
      case 'ping':
        return {};
      case 'tools/list':
        return {
          'tools': [for (final t in _tools.values) t.describe()],
        };
      case 'tools/call':
        final name = params['name'];
        final tool = _tools[name];
        if (tool == null) throw _RpcError(-32602, 'Unknown tool: $name');
        final args = params['arguments'];
        if (args != null && args is! Map) {
          throw const _RpcError(-32602, 'arguments must be an object');
        }
        try {
          final out = await tool.run(
            (args as Map?)?.cast<String, Object?>() ?? const {},
          );
          return {
            'content': [
              {'type': 'text', 'text': jsonEncode(out)},
            ],
            if (out is Map) 'structuredContent': out,
            'isError': false,
          };
        } on McpToolError catch (e) {
          return {
            'content': [
              {'type': 'text', 'text': e.message},
            ],
            'isError': true,
          };
        }
      default:
        // notifications/initialized, notifications/cancelled, …: nothing to
        // do. Unknown requests get "method not found".
        return method.startsWith('notifications/') ? {} : null;
    }
  }

  static Map<String, Object?> _error(Object? id, int code, String message) => {
    'jsonrpc': '2.0',
    'id': id,
    'error': {'code': code, 'message': message},
  };
}

class _RpcError implements Exception {
  const _RpcError(this.code, this.message);
  final int code;
  final String message;
}

/// Hosts accepted in `Host` and `Origin`: this machine only.
bool isLoopbackHost(String host) {
  final h = host.toLowerCase();
  return h == 'localhost' || h == '127.0.0.1' || h == '::1' || h == '[::1]';
}

/// The Streamable HTTP transport, reduced to what a stateless tool server
/// needs: `POST /mcp` with JSON in, JSON out. Bound to loopback only, and
/// requests whose `Host` or `Origin` isn't loopback are refused, so a web
/// page can't reach it through DNS rebinding.
class McpHttpServer {
  McpHttpServer._(this._servers, this.port, this._handler) {
    for (final s in _servers) {
      s.listen(_serve, onError: (Object e) => debugPrint('MCP: $e'));
    }
  }

  final List<HttpServer> _servers;
  final McpHandler _handler;
  final int port;

  static const path = '/mcp';
  static const _maxBody = 1 << 20;

  /// Binds 127.0.0.1:[port] (0 picks a free one), and ::1 on the same port
  /// when the machine has IPv6, so `localhost` works either way.
  static Future<McpHttpServer> start(McpHandler handler, {int port = 0}) async {
    final v4 = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    final servers = [v4];
    try {
      servers.add(
        await HttpServer.bind(
          InternetAddress.loopbackIPv6,
          v4.port,
          v6Only: true,
        ),
      );
    } on SocketException {
      // No IPv6 loopback; 127.0.0.1 is enough.
    }
    return McpHttpServer._(servers, v4.port, handler);
  }

  String get url => 'http://127.0.0.1:$port$path';

  Future<void> close() async {
    for (final s in _servers) {
      await s.close(force: true);
    }
  }

  Future<void> _serve(HttpRequest req) async {
    final res = req.response;
    try {
      final host = req.headers.host;
      if (host == null || !isLoopbackHost(host)) {
        return await _plain(res, HttpStatus.forbidden, 'Forbidden host');
      }
      final origin = req.headers.value('origin');
      if (origin != null) {
        final o = Uri.tryParse(origin);
        if (o == null || !o.hasAuthority || !isLoopbackHost(o.host)) {
          return await _plain(res, HttpStatus.forbidden, 'Forbidden origin');
        }
      }
      if (req.uri.path != path) {
        return await _plain(res, HttpStatus.notFound, 'Not found');
      }
      if (req.method != 'POST') {
        // No server-initiated stream (GET) and no sessions (DELETE).
        res.headers.set(HttpHeaders.allowHeader, 'POST');
        return await _plain(res, HttpStatus.methodNotAllowed, 'Use POST');
      }
      final bytes = <int>[];
      await for (final chunk in req) {
        bytes.addAll(chunk);
        if (bytes.length > _maxBody) {
          return await _plain(
            res,
            HttpStatus.requestEntityTooLarge,
            'Too large',
          );
        }
      }
      Object? message;
      try {
        message = jsonDecode(utf8.decode(bytes));
      } on FormatException {
        return await _json(res, {
          'jsonrpc': '2.0',
          'id': null,
          'error': {'code': -32700, 'message': 'Parse error'},
        });
      }
      final reply = await _handler.handle(message);
      if (reply == null) {
        res.statusCode = HttpStatus.accepted;
        await res.close();
        return;
      }
      await _json(res, reply);
    } catch (e) {
      debugPrint('MCP: request failed: $e');
      try {
        await _plain(res, HttpStatus.internalServerError, 'Error');
      } catch (_) {}
    }
  }

  static Future<void> _plain(HttpResponse res, int status, String text) {
    res.statusCode = status;
    res.headers.contentType = ContentType.text;
    res.write(text);
    return res.close();
  }

  static Future<void> _json(HttpResponse res, Object reply) {
    res.headers.contentType = ContentType.json;
    res.write(jsonEncode(reply));
    return res.close();
  }
}
