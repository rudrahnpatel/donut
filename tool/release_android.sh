#!/usr/bin/env bash
# Builds a signed release APK and publishes it as a GitHub Release, which the
# Android app's in-app updater picks up (lib/features/update/).
#
#   tool/release_android.sh [notes-file]
#
# Bump `version:` in pubspec.yaml first (both the name AND the +build number:
# Android refuses an update whose versionCode doesn't go up). Nothing is
# bumped automatically. The tag is v<name> (e.g. v1.1.0); the updater compares
# it to the installed version name, so every release needs a new name.
#
# Repo: $DONUT_UPDATE_REPO, else the value in release.json.
# Needs android/key.properties (the release keystore); refuses to publish a
# debug-signed APK.
set -euo pipefail
cd "$(dirname "$0")/.."

notes_file="${1:-}"
version="$(sed -n 's/^version:[[:space:]]*//p' pubspec.yaml | tr -d '[:space:]')"
name="${version%%+*}"
[[ -n "$name" ]] || { echo "no version in pubspec.yaml" >&2; exit 1; }
tag="v$name"
repo="${DONUT_UPDATE_REPO:-$(sed -n 's/.*"DONUT_UPDATE_REPO"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' release.json)}"

[[ -f google.json ]] || { echo "google.json missing: Google sync would break" >&2; exit 1; }
[[ -f android/key.properties ]] || {
  echo "android/key.properties missing: the APK would be debug-signed and" >&2
  echo "could never update an installed release. See README › Android releases." >&2
  exit 1
}

echo "Building Donut $version (tag $tag, repo ${repo:-<none>})"
# google.json: Google sign-in IDs. release.json: the update repo.
flutter build apk --release \
  --dart-define-from-file=google.json \
  --dart-define-from-file=release.json \
  ${DONUT_UPDATE_REPO:+--dart-define=DONUT_UPDATE_REPO=$DONUT_UPDATE_REPO}

mkdir -p build/release
apk="build/release/donut-$name.apk"
cp build/app/outputs/flutter-apk/app-release.apk "$apk"

# Refuse a debug-signed APK.
apksigner="$(ls -d "${ANDROID_HOME:-$HOME/Android/Sdk}"/build-tools/*/apksigner 2>/dev/null | sort -V | tail -1 || true)"
if [[ -n "$apksigner" ]]; then
  certs="$("$apksigner" verify --print-certs "$apk")"
  if grep -q "CN=Android Debug" <<<"$certs"; then
    echo "APK is debug-signed; not releasing." >&2
    exit 1
  fi
  grep -E "Signer #1 certificate (DN|SHA-256)" <<<"$certs"
fi
echo "APK: $apk ($(du -h "$apk" | cut -f1))"

if [[ -z "$notes_file" ]]; then
  notes_file="build/release/notes-$name.md"
  [[ -f "$notes_file" ]] || echo "Donut $version" >"$notes_file"
fi

if [[ -n "$repo" ]] && command -v gh >/dev/null && gh auth status >/dev/null 2>&1; then
  gh release create "$tag" "$apk" \
    --repo "$repo" \
    --title "Donut $name" \
    --notes-file "$notes_file" \
    --target "$(git rev-parse HEAD)"
  gh release view "$tag" --repo "$repo"
else
  cat <<EOF

gh is not installed/authenticated (or no repo set). Publish by hand:
  1. https://github.com/${repo:-<owner>/donut}/releases/new
  2. Tag: $tag (target: $(git rev-parse --short HEAD)), title: Donut $name
  3. Paste the notes from $notes_file, attach $apk
  4. Publish (not as draft or pre-release: the app ignores those)
EOF
fi
