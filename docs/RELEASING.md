# Releases & local builds

Flutter 3.47.9, Java 17, Android SDK 36. Phone and watch use the same application ID,
version and signing certificate so Wear OS Data Layer can exchange sessions.

## One-time private signing setup

Create and back up a private Android release keystore. Never commit it, its passwords,
or an exported base64 copy. Add these repository **Actions secrets**:

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded JKS keystore |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_ALIAS` | Signing alias |
| `ANDROID_KEY_PASSWORD` | Key password |

A tagged build deliberately fails if any secret is absent. Changing the signing key
breaks Android updates; preserve the key for all future releases. Development builds
without secrets use an ephemeral debug key and are not an update channel. Export a
JSON backup before replacing a development build with a signed release.

## Publish

```sh
git tag v1.1.0
git push origin v1.1.0
```

Tags must be stable `vMAJOR.MINOR.PATCH`. Android versionCode is
`major × 1,000,000 + minor × 1,000 + patch` (minor/patch < 1000).
CI checks Dart, tests both interfaces, verifies audio, builds both APKs with the
same key, runs native persistence tests, and publishes a Release with APKs,
SHA256SUMS and generated release notes. Releases are created only after all checks
pass. Use increasing versions; do not move an existing release tag.

## Build locally

```sh
flutter pub get --enforce-lockfile
flutter build apk --release --flavor wear --dart-define=WEAR=true
mkdir -p android/app/src/phone/assets/wear
cp build/app/outputs/flutter-apk/app-wear-release.apk android/app/src/phone/assets/wear/easy-hof-wear.apk
flutter build apk --release --flavor phone
```

Only the phone Android source set bundles the watch APK, preventing recursive APK
embedding. Set `KEYSTORE_PATH`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`
for a production signature. Without a bundled APK the installer displays an error;
it does not download or install arbitrary packages.

## Device validation

Before a public release, test pairing/install/update on a physical Wear OS 3+ watch
and verify heart rate and delayed Data Layer sync. CI cannot validate a real watch's
pairing screen, manufacturer firmware, radio connection or sensor permissions.
