"""Check Play permissions and discover internal tracks using a temporary edit.

No bundles or releases are changed and the temporary edit is always deleted.
"""
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

PACKAGE = 'io.github.andi_0309.easyhof'
API = 'https://androidpublisher.googleapis.com/androidpublisher/v3'


class Publisher:
    def __init__(self, token):
        self.token = token

    def request(self, method, path, body=None):
        request = urllib.request.Request(
            API + '/applications/' + PACKAGE + '/edits' + path,
            data=json.dumps(body).encode() if body is not None else None,
            headers={'Authorization': 'Bearer ' + self.token,
                     'Content-Type': 'application/json'},
            method=method,
        )
        try:
            with urllib.request.urlopen(request, timeout=45) as response:
                data = response.read()
                return json.loads(data) if data else {}
        except urllib.error.HTTPError as error:
            payload = error.read().decode(errors='replace')
            try:
                message = json.loads(payload)['error']['message']
            except (ValueError, KeyError, TypeError):
                message = 'Request rejected'
            message = message.replace(self.token, '[REDACTED]')
            raise RuntimeError(f'Google Play API HTTP {error.code}: {message}') from None


def internal_tracks(tracks):
    names = {track.get('track') for track in tracks}
    phone = next((name for name in ['internal', 'qa'] if name in names), None)
    wear = next((name for name in ['wear:internal', 'wear:qa'] if name in names), None)
    if not phone or not wear:
        raise RuntimeError('Create internal test tracks for both phone and Wear OS in Play Console. '
                           'Available tracks: ' + ', '.join(sorted(name for name in names if name)))
    return phone, wear


def check_access(client):
    edit = client.request('POST', '', {})
    edit_path = '/' + urllib.parse.quote(edit['id'], safe='')
    try:
        response = client.request('GET', edit_path + '/tracks')
        return internal_tracks(response.get('tracks', []))
    finally:
        client.request('DELETE', edit_path)


if __name__ == '__main__':
    try:
        phone, wear = check_access(Publisher(os.environ['GOOGLE_PLAY_ACCESS_TOKEN']))
        print(f'Google Play access verified. Phone track: {phone}; Wear OS track: {wear}.')
        print('Temporary edit deleted; no releases or bundles changed.')
        with open(os.environ['GITHUB_OUTPUT'], 'a') as output:
            output.write(f'phone_track={phone}\nwear_track={wear}\n')
    except (RuntimeError, urllib.error.URLError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
