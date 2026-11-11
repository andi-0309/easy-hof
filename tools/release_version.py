"""Validate release names and allocate increasing, distinct Android version codes."""
import os
from pathlib import Path
import re
import sys


def version_name(tag):
    if not re.fullmatch(r'v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)', tag):
        raise ValueError('Versions must use vMAJOR.MINOR.PATCH (e.g. v1.1.0)')
    return tag[1:]


def version_codes(run_number):
    if not isinstance(run_number, int) or isinstance(run_number, bool) or run_number < 1:
        raise ValueError('GitHub run number must be positive')
    phone = 10_000_000 + run_number * 2
    if phone + 1 > 2_100_000_000:
        raise ValueError('Android version code limit exceeded')
    return phone, phone + 1


if __name__ == '__main__':
    tag = sys.argv[1] if len(sys.argv) > 1 else ''
    if not tag:
        match = re.search(r'^version:\s*(\d+\.\d+\.\d+)(?:\+\d+)?\s*$',
                          Path('pubspec.yaml').read_text(), re.MULTILINE)
        if not match:
            raise ValueError('pubspec.yaml must contain a semantic version')
        tag = 'v' + match.group(1)
    name = version_name(tag)
    phone, wear = version_codes(int(os.environ['GITHUB_RUN_NUMBER']))
    with open(os.environ['GITHUB_ENV'], 'a') as output:
        output.write(f'RELEASE_VERSION={name}\nPHONE_CODE={phone}\nWEAR_CODE={wear}\n')
