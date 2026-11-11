"""Validate signed Play bundles, their identity, versions and distribution contents."""
import argparse
import hashlib
import os
from pathlib import Path
import subprocess
import xml.etree.ElementTree as ET
import zipfile

ANDROID = '{http://schemas.android.com/apk/res/android}'
EXPECTED_PACKAGE = 'io.github.andi_0309.easyhof'


def run(args):
    return subprocess.run(args, check=True, capture_output=True).stdout


def validate(bundle, bundletool, version_code, wear, certificate):
    run(['java', '-jar', str(bundletool), 'validate', '--bundle=' + str(bundle)])
    manifest = ET.fromstring(run(['java', '-jar', str(bundletool), 'dump',
                                 'manifest', '--bundle=' + str(bundle)]))
    assert manifest.attrib['package'] == EXPECTED_PACKAGE, 'Incorrect package'
    assert int(manifest.attrib[ANDROID + 'versionCode']) == version_code, 'Incorrect version code'
    watches = [f for f in manifest.findall('uses-feature')
               if f.get(ANDROID + 'name') == 'android.hardware.type.watch']
    assert bool(watches) == wear, 'Incorrect form factor'
    if wear:
        assert watches[0].get(ANDROID + 'required', 'true') == 'true'
        standalone = next((meta for meta in manifest.findall('application/meta-data')
                           if meta.get(ANDROID + 'name') == 'com.google.android.wearable.standalone'), None)
        assert standalone is not None and standalone.get(ANDROID + 'value') == 'false'
    with zipfile.ZipFile(bundle) as archive:
        assert archive.testzip() is None, 'Corrupt ZIP entry'
        assert not any(p.endswith('.apk') for p in archive.namelist()), 'Embedded APK in Play bundle'
        assert not any('conscrypt' in p.lower() and p.endswith('.so') for p in archive.namelist()), 'ADB TLS library in Play bundle'
    run(['jarsigner', '-verify', str(bundle)])
    pem = run(['keytool', '-printcert', '-jarfile', str(bundle), '-rfc'])
    actual = run_certificate(pem)
    assert actual == certificate, 'Signing certificate differs from configured release key'
    print(f'{bundle.name}: package, version {version_code}, signature and contents verified')


def run_certificate(pem):
    return subprocess.run(['openssl', 'x509', '-outform', 'DER'], input=pem,
                          check=True, capture_output=True).stdout


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--phone', type=Path, required=True)
    parser.add_argument('--wear', type=Path, required=True)
    parser.add_argument('--bundletool', type=Path, required=True)
    args = parser.parse_args()
    certificate = run(['keytool', '-exportcert', '-keystore', os.environ['KEYSTORE_PATH'],
                       '-alias', os.environ['KEY_ALIAS'], '-storepass:env', 'KEYSTORE_PASSWORD'])
    phone_code, wear_code = int(os.environ['PHONE_CODE']), int(os.environ['WEAR_CODE'])
    assert wear_code > phone_code
    validate(args.phone, args.bundletool, phone_code, False, certificate)
    validate(args.wear, args.bundletool, wear_code, True, certificate)
    print('Release certificate SHA-256:', hashlib.sha256(certificate).hexdigest())
