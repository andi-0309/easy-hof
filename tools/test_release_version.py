import unittest
from release_version import version_name, version_codes


class ReleaseVersionTest(unittest.TestCase):
    def test_versions_reject_malformed_or_prerelease_tags(self):
        self.assertEqual(version_name('v1.1.0'), '1.1.0')
        for tag in ['1.1.0', 'v01.1.0', 'v1.1', 'v1.1.0-beta', 'v1.1.0;echo test']:
            with self.assertRaises(ValueError):
                version_name(tag)

    def test_next_build_upgrades_both_form_factors(self):
        previous_phone, previous_wear = version_codes(100)
        phone, wear = version_codes(101)
        self.assertGreater(previous_phone, 1_001_000)
        self.assertGreater(phone, previous_wear)
        self.assertGreater(wear, phone)
        self.assertNotEqual(previous_phone, previous_wear)

    def test_android_bounds_are_enforced(self):
        for value in [0, -1, True, 2_100_000_000]:
            with self.assertRaises(ValueError):
                version_codes(value)


if __name__ == '__main__':
    unittest.main()
