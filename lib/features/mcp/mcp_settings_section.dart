import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../day/pickers.dart';
import 'mcp_provider.dart';

/// Settings › Claude (desktop only): the MCP server switch, its port, and
/// the command that connects Claude Code to it.
class McpSettingsSection extends ConsumerWidget {
  const McpSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final status = ref.watch(mcpServerProvider);
    final repo = ref.read(settingsRepoProvider);
    final scheme = Theme.of(context).colorScheme;
    final url = 'http://127.0.0.1:${s.mcpPort}/mcp';
    final command = 'claude mcp add --transport http donut $url';

    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Let Claude plan with Donut'),
            subtitle: Text(
              !s.mcpServer
                  ? 'Off'
                  : status.error ??
                        (status.running
                            ? 'MCP server on ${status.url}, this computer only'
                            : 'Starting…'),
              style: status.error != null && s.mcpServer
                  ? TextStyle(color: scheme.error)
                  : null,
            ),
            value: s.mcpServer,
            onChanged: (v) => repo.save(s.copyWith(mcpServer: v)),
          ),
          ListTile(
            enabled: s.mcpServer,
            title: const Text('Port'),
            trailing: Text('${s.mcpPort}'),
            onTap: () async {
              final text = await promptText(
                context,
                title: 'MCP port',
                initial: '${s.mcpPort}',
                hint: '47821',
              );
              final port = int.tryParse(text?.trim() ?? '');
              if (port != null && port >= 1024 && port <= 65535) {
                await repo.save(s.copyWith(mcpPort: port));
              }
            },
          ),
          ListTile(
            enabled: s.mcpServer,
            title: const Text('Connect Claude Code'),
            subtitle: SelectableText(
              command,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            trailing: IconButton(
              tooltip: 'Copy',
              icon: const Icon(Icons.copy_rounded),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: command));
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Copied')));
              },
            ),
          ),
        ],
      ),
    );
  }
}
