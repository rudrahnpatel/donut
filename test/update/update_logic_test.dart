import 'dart:convert';

import 'package:donut/features/update/update_logic.dart';
import 'package:flutter_test/flutter_test.dart';

AppVersion v(String s) => AppVersion.tryParse(s)!;

ReleaseAsset apk(String name, {int size = 100}) => ReleaseAsset(
  name: name,
  url: 'https://example.com/$name',
  size: size,
  contentType: 'application/vnd.android.package-archive',
);

void main() {
  group('AppVersion', () {
    test('parses tags with and without v and build numbers', () {
      expect(v('v1.2.3').toString(), '1.2.3');
      expect(v('1.2.3+45').build, 45);
      expect(v('V2.0').toString(), '2.0.0');
      expect(AppVersion.tryParse('nightly'), isNull);
      expect(AppVersion.tryParse('1.2.3-beta'), isNull);
      expect(AppVersion.tryParse(''), isNull);
    });

    test('fromPackage combines version and build number', () {
      expect(AppVersion.fromPackage('1.0.0', '7').toString(), '1.0.0+7');
      expect(AppVersion.fromPackage('1.0.0', '').toString(), '1.0.0');
    });

    test('compares major, minor, patch numerically', () {
      expect(v('1.10.0').isNewerThan(v('1.9.9')), isTrue);
      expect(v('2.0.0').isNewerThan(v('1.99.99+999')), isTrue);
      expect(v('1.0.0').isNewerThan(v('1.0.1')), isFalse);
    });

    test('build number breaks ties only when both sides have one', () {
      expect(v('v1.0.0+2').isNewerThan(v('1.0.0+1')), isTrue);
      expect(v('v1.0.0+1').isNewerThan(v('1.0.0+2')), isFalse);
      expect(v('v1.0.0').isNewerThan(v('1.0.0+5')), isFalse);
      expect(v('v1.0.0+9').isNewerThan(v('1.0.0')), isFalse);
      expect(v('1.0.0+3').compareTo(v('1.0.0+3')), 0);
    });
  });

  group('pickApk', () {
    test('prefers the split APK for the device ABI', () {
      final assets = [
        apk('donut-armeabi-v7a.apk'),
        apk('donut-arm64-v8a.apk'),
        apk('donut-x86_64.apk'),
        apk('donut.apk'),
      ];
      expect(pickApk(assets)!.name, 'donut-arm64-v8a.apk');
      expect(
        pickApk(assets, deviceAbis: ['x86_64', 'x86'])!.name,
        'donut-x86_64.apk',
      );
      expect(
        pickApk(assets, deviceAbis: ['armeabi-v7a'])!.name,
        'donut-armeabi-v7a.apk',
      );
    });

    test('falls back to a universal APK', () {
      final assets = [
        ReleaseAsset(
          name: 'checksums.txt',
          url: 'u',
          size: 1,
          contentType: 'text/plain',
        ),
        apk('donut-1.2.0+3.apk'),
      ];
      expect(pickApk(assets)!.name, 'donut-1.2.0+3.apk');
    });

    test('x86 device does not take the x86_64 split', () {
      final assets = [apk('donut-x86_64.apk')];
      expect(pickApk(assets, deviceAbis: ['x86']), isNull);
    });

    test('null without any APK', () {
      expect(pickApk(const []), isNull);
      expect(pickApk([apk('donut-armeabi-v7a.apk')]), isNull);
    });
  });

  group('release JSON', () {
    // Trimmed from a real `GET /repos/{owner}/{repo}/releases/latest`.
    const body = '''
{
  "html_url": "https://github.com/someone/donut/releases/tag/v1.1.0+2",
  "tag_name": "v1.1.0+2",
  "name": "Donut 1.1.0",
  "draft": false,
  "prerelease": false,
  "body": "- Faster dial\\n- Fixes",
  "assets": [
    {
      "name": "donut-1.1.0+2.apk",
      "content_type": "application/vnd.android.package-archive",
      "size": 23456789,
      "browser_download_url": "https://github.com/someone/donut/releases/download/v1.1.0%2B2/donut-1.1.0+2.apk"
    }
  ]
}''';

    ReleaseInfo parse([Map<String, dynamic> patch = const {}]) =>
        ReleaseInfo.fromJson({
          ...jsonDecode(body) as Map<String, dynamic>,
          ...patch,
        });

    test('parses tag, notes and assets', () {
      final r = parse();
      expect(r.tag, 'v1.1.0+2');
      expect(r.version.toString(), '1.1.0+2');
      expect(r.notes, '- Faster dial\n- Fixes');
      expect(r.assets.single.size, 23456789);
      expect(r.assets.single.url, endsWith('.apk'));
    });

    test('tolerates missing fields', () {
      final r = ReleaseInfo.fromJson({'tag_name': 'v1.0.0'});
      expect(r.assets, isEmpty);
      expect(r.notes, '');
      expect(r.draft, isFalse);
    });

    test('offers a newer release with an APK', () {
      final offer = offerFor(parse(), v('1.0.0+1'));
      expect(offer, isNotNull);
      expect(offer!.version.toString(), '1.1.0+2');
      expect(offer.apk.name, 'donut-1.1.0+2.apk');
    });

    test('no offer when same, older, draft, prerelease or no APK', () {
      expect(offerFor(parse(), v('1.1.0+2')), isNull);
      expect(offerFor(parse(), v('1.2.0+1')), isNull);
      expect(offerFor(parse({'draft': true}), v('1.0.0')), isNull);
      expect(offerFor(parse({'prerelease': true}), v('1.0.0')), isNull);
      expect(offerFor(parse({'assets': []}), v('1.0.0')), isNull);
      expect(offerFor(parse({'tag_name': 'latest'}), v('1.0.0')), isNull);
    });
  });
}
