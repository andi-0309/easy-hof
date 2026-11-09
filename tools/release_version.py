"""Map vMAJOR.MINOR.PATCH to a stable, increasing Android version code."""
import os
import re
import sys

def version(tag):
    match = re.fullmatch(r'v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)', tag)
    if not match:
        raise ValueError('Release tags must use vMAJOR.MINOR.PATCH (e.g. v1.1.0)')
    major, minor, patch = map(int, match.groups())
    if not (major <= 2000 and minor < 1000 and patch < 1000):
        raise ValueError('Version exceeds the supported Android version code range')
    code = major * 1_000_000 + minor * 1000 + patch
    if code < 1:
        raise ValueError('Version code must be positive')
    return tag[1:], code

if __name__ == '__main__':
    name, code = version(sys.argv[1])
    with open(os.environ['GITHUB_ENV'], 'a') as output:
        output.write(f'RELEASE_VERSION={name}\nRELEASE_CODE={code}\n')
