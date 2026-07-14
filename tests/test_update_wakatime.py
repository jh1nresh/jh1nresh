import datetime as dt
import unittest

from scripts.update_wakatime import END_MARKER, START_MARKER, render_section, replace_section


class UpdateWakaTimeTests(unittest.TestCase):
    def test_renders_only_language_evidence(self):
        section = render_section(
            {
                "human_readable_total": "10 hrs",
                "end": "2026-07-14T23:59:59Z",
                "projects": [{"name": "private-project"}],
                "languages": [
                    {"name": "Swift", "text": "6 hrs", "percent": 60, "total_seconds": 21600},
                    {"name": "Python", "text": "4 hrs", "percent": 40, "total_seconds": 14400},
                ],
            }
        )

        self.assertIn("Swift", section)
        self.assertIn("Python", section)
        self.assertIn("2026-07-14", section)
        self.assertNotIn("private-project", section)

    def test_replaces_one_marker_pair(self):
        readme = f"before\n{START_MARKER}\nold\n{END_MARKER}\nafter\n"
        updated = replace_section(readme, "new\\language")
        self.assertEqual(
            updated,
            f"before\n{START_MARKER}\nnew\\language\n{END_MARKER}\nafter\n",
        )

    def test_uses_a_stable_fallback_date(self):
        section = render_section({}, fallback_date=dt.date(2026, 7, 14))
        self.assertIn("2026-07-14", section)
        self.assertIn("No language activity", section)

    def test_rejects_missing_markers(self):
        with self.assertRaisesRegex(RuntimeError, "exactly one"):
            replace_section("no markers", "new")


if __name__ == "__main__":
    unittest.main()
