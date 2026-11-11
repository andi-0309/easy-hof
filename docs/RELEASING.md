# Releases, Play testing and local builds

Flutter 3.47.9, Java 17, Android SDK 36. Both form factors use the application ID
and Kotlin namespace `io.github.andi_0309.easyhof`, the same version name and the
same signing certificate. Android version codes are distinct for phone and watch.

The former package identity is a separate Android app. Existing users can export
its JSON backup and import it into the new app. Install the new identity on both
phone and watch for synchronization.

## Private signing

Back up the private release keystore and never commit its contents or passwords.
Configure repository Actions secrets:

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded JKS keystore |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_ALIAS` | Signing alias |
| `ANDROID_KEY_PASSWORD` | Key password |

Tagged builds require all four secrets. Signed main-branch builds also generate
Play bundles. Pull requests and builds without signing secrets produce APKs with
a development signature, and do not generate uploadable Play bundles.

In Play App Signing, import the existing release key with Google's PEPK tool.
The Play app-signing certificate must match the GitHub APK certificate for
cross-source updates and Wear OS Data Layer communication. Keep the private key
and its backup for future releases. Export JSON before replacing an installation
that has a different signature.

## Versions

Tags use stable `vMAJOR.MINOR.PATCH` and determine the displayed version name.
Other builds take that name from `pubspec.yaml`.

Every CI build uses the workflow's increasing `GITHUB_RUN_NUMBER`:

- Phone versionCode: `10,000,000 + 2 × run number`.
- Wear versionCode: phone versionCode + 1.

This keeps both form factors unique and makes the next workflow run newer than
both preceding APKs/AABs. Preserve the workflow's run counter; if moving to a new
workflow or repository, adjust the offset above the highest published code.
The new range also exceeds the version codes used by earlier semantic-tag builds.

## Internal Play test

Download and unzip the **play-store-bundles** Actions artifact. It contains:

- `easy-hof-phone.aab`: upload to the phone internal test track.
- `easy-hof-wear.aab`: upload to the Wear OS internal test track.
- `PLAY-SHA256SUMS`: integrity checksums.

Enable the Wear OS form factor in Play Console and register the tester's Google
account. The account must opt in to the corresponding test. Both form factors
need available releases before testing the store installation flow.

CI validates bundles with pinned Google bundletool 1.18.2, checks the package,
version codes and Wear standalone feature, and verifies the JAR signature and
certificate against the configured private release keystore. Neither AAB contains
an embedded APK or the removed wireless-ADB installer's native TLS libraries.
These checks do not replace Google Play's policy review or physical device tests.

## GitHub releases

```sh
git tag v1.1.0
git push origin v1.1.0
```

After all checks pass, CI publishes APKs, AABs, checksums and release notes.
GitHub/Obtainium users install `easy-hof-phone.apk`; the watch APK is available
for developers. All phone distributions open the Play Store for watch installation.
The watch installer no longer uses Wireless debugging or bundled APKs.

## Build locally

```sh
flutter pub get --enforce-lockfile
flutter build apk --release --flavor phone
flutter build apk --release --flavor wear --dart-define=WEAR=true
flutter build appbundle --release --flavor phone --build-name 1.1.0 --build-number PHONE_CODE
flutter build appbundle --release --flavor wear --dart-define=WEAR=true --build-name 1.1.0 --build-number WEAR_CODE
```

Replace `PHONE_CODE` and `WEAR_CODE` with unique increasing codes above the
highest published versions. For production signing, set `KEYSTORE_PATH`,
`KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD` in the local environment.

Before a public release, validate installation through Google Play on a physical
watch, heart-rate permissions, standalone cold sessions and delayed phone sync.
