import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../day/plan_mode.dart';
import 'mcp_server.dart';
import 'mcp_tools.dart';

/// The MCP server runs on the desktop builds only.
bool get mcpSupported => !kIsWeb && (Platform.isLinux || Platform.isWindows);

/// What Settings shows about the MCP server.
class McpStatus {
  const McpStatus({this.url, this.error});

  /// Where it listens while running.
  final String? url;
  final String? error;

  bool get running => url != null;
}

/// Runs the localhost MCP server while the setting is on, restarting it
/// when the port changes and closing it when the app's providers go away.
/// Kept alive by `DonutApp`, so it runs from launch (before onboarding
/// finishes too).
final mcpServerProvider = NotifierProvider<McpServerController, McpStatus>(
  McpServerController.new,
);

class McpServerController extends Notifier<McpStatus> {
  @override
  McpStatus build() {
    if (!mcpSupported || !ref.watch(settingsLoadedProvider)) {
      return const McpStatus();
    }
    final (on, port) = ref.watch(
      settingsProvider.select((s) => (s.mcpServer, s.mcpPort)),
    );
    if (!on) return const McpStatus();

    final tools = DonutMcpTools(
      blocks: ref.read(blockRepoProvider),
      pins: ref.read(pinRepoProvider),
      library: ref.read(libraryRepoProvider),
      work: ref.read(workRepoProvider),
      planModeOn: () => ref.read(planModeProvider),
    );
    var disposed = false;
    McpHttpServer? server;
    ref.onDispose(() {
      disposed = true;
      server?.close();
    });
    McpHttpServer.start(McpHandler(tools.tools), port: port).then(
      (s) {
        if (disposed) {
          s.close();
          return;
        }
        server = s;
        debugPrint('MCP: listening on ${s.url}');
        state = McpStatus(url: s.url);
      },
      onError: (Object e) {
        debugPrint('MCP: could not listen on 127.0.0.1:$port: $e');
        if (!disposed) {
          state = McpStatus(
            error: e is SocketException
                ? 'Port $port is in use (is Donut already open?)'
                : '$e',
          );
        }
      },
    );
    return const McpStatus();
  }
}
