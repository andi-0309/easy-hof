"""Ensure the phone carries exactly the separate watch APK, without recursion."""
import hashlib
import sys
import zipfile
from pathlib import Path

phone, wear = map(Path, sys.argv[1:])
with zipfile.ZipFile(phone) as apk:
    assert apk.getinfo('assets/wear/easy-hof-wear.apk').compress_type == zipfile.ZIP_STORED, 'Watch APK must be uncompressed for streaming installation'
    embedded = apk.read('assets/wear/easy-hof-wear.apk')
    assert hashlib.sha256(embedded).digest() == hashlib.sha256(wear.read_bytes()).digest(), 'Bundled watch APK differs'
with zipfile.ZipFile(wear) as apk:
    assert not any(name.endswith('.apk') for name in apk.namelist()), 'Recursive APK embedding'
print('Matching watch APK embedded only in phone flavor.')
