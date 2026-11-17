/// Pure parts of the Android in-app updater: version parsing and comparison,
/// GitHub release JSON, and picking the APK for this device. No Flutter or
/// platform imports, so it is unit-tested on any host.
library;

/// The GitHub repo (`owner/name`) whose Releases carry Donut's APKs. Override
/// with `--dart-define=DONUT_UPDATE_REPO=...` (release.json sets it); an empty
/// value turns the updater off.
const updateRepo = String.fromEnvironment(
  'DONUT_UPDATE_REPO',
  defaultValue: 'rudrahnpatel/donut',
);

/// `1.2.3` or `1.2.3+45` (an optional leading `v`, as in git tags).
class AppVersion implements Comparable<AppVersion> {
  const AppVersion(this.major, this.minor, this.patch, [this.build]);

  final int major;
  final int minor;
  final int patch;

  /// The `+N` build number (Android versionCode); null when the tag has none.
  final int? build;

  static final _re = RegExp(
    r'^[vV]?(\d+)(?:\.(\d+))?(?:\.(\d+))?(?:\+(\d+))?$',
  );

  /// Null when [text] isn't a plain version (e.g. `nightly`, `1.2.3-beta`).
  static AppVersion? tryParse(String text) {
    final m = _re.firstMatch(text.trim());
    if (m == null) return null;
    int? n(int i) => m.group(i) == null ? null : int.parse(m.group(i)!);
    return AppVersion(n(1)!, n(2) ?? 0, n(3) ?? 0, n(4));
  }

  /// From package_info: `version` is `1.2.3`, `buildNumber` is `45` (or empty).
  static AppVersion? fromPackage(String version, String buildNumber) {
    final v = tryParse(version);
    if (v == null) return null;
    return AppVersion(v.major, v.minor, v.patch, int.tryParse(buildNumber));
  }

  /// Compares major.minor.patch, then build numbers when both sides have one.
  /// A missing build number never makes a version newer or older.
  @override
  int compareTo(AppVersion other) {
    for (final (a, b) in [
      (major, other.major),
      (minor, other.minor),
      (patch, other.patch),
    ]) {
      if (a != b) return a.compareTo(b);
    }
    if (build != null && other.build != null) {
      return build!.compareTo(other.build!);
    }
    return 0;
  }

  bool isNewerThan(AppVersion other) => compareTo(other) > 0;

  @override
  String toString() => '$major.$minor.$patch${build == null ? '' : '+$build'}';
}

class ReleaseAsset {
  const ReleaseAsset({
    required this.name,
    required this.url,
    required this.size,
    required this.contentType,
  });

  final String name;

  /// `browser_download_url` (redirects to the CDN).
  final String url;
  final int size;
  final String contentType;

  bool get isApk =>
      name.toLowerCase().endsWith('.apk') ||
      contentType == 'application/vnd.android.package-archive';
}

class ReleaseInfo {
  const ReleaseInfo({
    required this.tag,
    required this.name,
    required this.notes,
    required this.htmlUrl,
    required this.draft,
    required this.prerelease,
    required this.assets,
  });

  final String tag;
  final String name;

  /// The release body (markdown), shown as-is in the prompt.
  final String notes;
  final String htmlUrl;
  final bool draft;
  final bool prerelease;
  final List<ReleaseAsset> assets;

  AppVersion? get version => AppVersion.tryParse(tag);

  /// Parses one release from `GET /repos/{repo}/releases/latest`.
  factory ReleaseInfo.fromJson(Map<String, dynamic> json) => ReleaseInfo(
    tag: json['tag_name'] as String? ?? '',
    name: json['name'] as String? ?? '',
    notes: json['body'] as String? ?? '',
    htmlUrl: json['html_url'] as String? ?? '',
    draft: json['draft'] as bool? ?? false,
    prerelease: json['prerelease'] as bool? ?? false,
    assets: [
      for (final a in (json['assets'] as List<dynamic>? ?? const []))
        if (a is Map<String, dynamic>)
          ReleaseAsset(
            name: a['name'] as String? ?? '',
            url: a['browser_download_url'] as String? ?? '',
            size: (a['size'] as num?)?.toInt() ?? 0,
            contentType: a['content_type'] as String? ?? '',
          ),
    ],
  );
}

const _knownAbis = ['arm64-v8a', 'armeabi-v7a', 'x86_64', 'x86'];

/// The APK to download for a device supporting [deviceAbis] (most preferred
/// first, as Android's Build.SUPPORTED_ABIS): a split APK for the first ABI
/// that has one, else a universal APK (no ABI in its name). Null when the
/// release has no APK this device can run.
ReleaseAsset? pickApk(
  List<ReleaseAsset> assets, {
  List<String> deviceAbis = const ['arm64-v8a'],
}) {
  final apks = [
    for (final a in assets)
      if (a.isApk && a.url.isNotEmpty) a,
  ];
  String? abiOf(ReleaseAsset a) {
    final n = a.name.toLowerCase();
    // Check longer names first: "x86" is inside "x86_64".
    for (final abi in _knownAbis) {
      if (n.contains(abi)) return abi;
    }
    return null;
  }

  for (final abi in deviceAbis) {
    for (final a in apks) {
      if (abiOf(a) == abi) return a;
    }
  }
  for (final a in apks) {
    if (abiOf(a) == null) return a;
  }
  return null;
}

/// An update worth offering: [release] is newer than the running app and
/// has an APK for this device.
class UpdateOffer {
  const UpdateOffer(this.release, this.version, this.apk);

  final ReleaseInfo release;
  final AppVersion version;
  final ReleaseAsset apk;
}

/// Decides whether [release] is an update for [current]. Drafts,
/// prereleases, unparseable tags, older versions and releases without a
/// matching APK give null.
UpdateOffer? offerFor(
  ReleaseInfo release,
  AppVersion current, {
  List<String> deviceAbis = const ['arm64-v8a'],
}) {
  if (release.draft || release.prerelease) return null;
  final v = release.version;
  if (v == null || !v.isNewerThan(current)) return null;
  final apk = pickApk(release.assets, deviceAbis: deviceAbis);
  if (apk == null) return null;
  return UpdateOffer(release, v, apk);
}
