# donut

Donut — plan your day on a clock

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Plan with Claude (desktop MCP server)

On Linux and Windows, Donut runs a local [MCP](https://modelcontextprotocol.io) server while
it is open, so Claude can read and plan your day. It listens on
`http://127.0.0.1:47821/mcp` (loopback only; requests with a non-local `Host` or `Origin`
are refused). Turn it off or change the port in **Settings › Claude**.

Connect Claude Code (Donut must be running):

```sh
claude mcp add --transport http donut http://127.0.0.1:47821/mcp
```

For Claude Desktop (its custom connectors run from the cloud and can't reach
`127.0.0.1`), bridge it as a local server in `claude_desktop_config.json`:

```json
{"mcpServers": {"donut": {"command": "npx", "args": ["-y", "mcp-remote", "http://127.0.0.1:47821/mcp"]}}}
```

Tools: `get_day`, `list_blocks`, `add_block`, `update_block`, `delete_block`,
`find_free_slots`, `list_activities`, `add_pin`, `delete_pin`. Dates are `YYYY-MM-DD`, times
24h `HH:MM` in local wall-clock time. Changes go through the same code as the dial: they
save instantly, or become sketches you approve with ✓ while Donut is in plan mode.

## Android releases and in-app updates

The Android app updates itself from GitHub Releases of
[`rudrahnpatel/donut`](https://github.com/rudrahnpatel/donut). On start (at most every 6 hours)
and from **Settings › About › Check for updates**, it asks
`api.github.com/repos/<repo>/releases/latest`, and if the tag is newer than the installed
version it offers **Later / Skip this version / Update**. Update downloads the APK and opens
Android's installer. **The installer's confirm screen is the end state**: a normal app can't
install silently. The first time, Android asks you to let Donut "Install unknown apps".

The repo comes from `release.json` (`DONUT_UPDATE_REPO`, `owner/name`; empty turns updates
off). Debug builds never check on their own.

### Signing

Release builds are signed with the key in `android/key.properties` (gitignored), which points
at a keystore outside the repo (`~/.config/donut/release.jks`). Without that file, release
builds fall back to the debug key and can't update an installed release.

**Back up the keystore and its password (from `key.properties`) somewhere safe.** If the key
is lost, no future APK can update existing installs; everyone would have to uninstall
(losing unsynced local data) and reinstall.

### Publishing a release

1. Bump `version:` in `pubspec.yaml`: a new name **and** a higher `+build`
   (e.g. `1.1.0+2` → `1.2.0+3`). Android rejects an update whose build number doesn't go up,
   and the updater compares the tag `v<name>`.
2. Commit and push.
3. `tool/release_android.sh [notes.md]`: builds
   `flutter build apk --release --dart-define-from-file=google.json --dart-define-from-file=release.json`,
   refuses a debug-signed APK, copies it to `build/release/donut-<name>.apk`, and runs
   `gh release create v<name>` when `gh` is installed and logged in (else prints manual steps).

Don't publish drafts or pre-releases for users; the app ignores them. Build universal APKs
(not `--split-per-abi`, which adds 1000×ABI to the build number).
