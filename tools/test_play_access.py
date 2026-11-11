import unittest
from check_play_access import check_access, internal_tracks


class PlayAccessTest(unittest.TestCase):
    def test_internal_names_and_legacy_names(self):
        for phone, wear in [('internal', 'wear:internal'), ('qa', 'wear:qa')]:
            self.assertEqual(internal_tracks([{'track': phone}, {'track': wear},
                                              {'track': 'production'}]), (phone, wear))
        with self.assertRaises(RuntimeError):
            internal_tracks([{'track': 'internal'}, {'track': 'wear:production'}])

    def test_access_check_cleans_up_without_committing(self):
        class Client:
            def __init__(self):
                self.calls = []

            def request(self, method, path, body=None):
                self.calls.append((method, path))
                if method == 'POST':
                    return {'id': 'temporary-id'}
                if method == 'GET':
                    return {'tracks': [{'track': 'internal'}, {'track': 'wear:internal'}]}
                return {}

        client = Client()
        self.assertEqual(check_access(client), ('internal', 'wear:internal'))
        self.assertEqual(client.calls, [('POST', ''), ('GET', '/temporary-id/tracks'),
                                        ('DELETE', '/temporary-id')])

    def test_failed_track_check_also_deletes_edit(self):
        class Client:
            def __init__(self):
                self.deleted = False

            def request(self, method, path, body=None):
                if method == 'POST':
                    return {'id': 'temporary-id'}
                if method == 'GET':
                    raise RuntimeError('permission denied')
                self.deleted = True
                return {}

        client = Client()
        with self.assertRaises(RuntimeError):
            check_access(client)
        self.assertTrue(client.deleted)


if __name__ == '__main__':
    unittest.main()
