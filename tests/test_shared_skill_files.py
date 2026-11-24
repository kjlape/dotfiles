"""Run with: python3 -m unittest discover -s tests -v"""

from pathlib import Path
import unittest

SKILLS = Path(__file__).resolve().parents[1] / "skills"

# Files that must stay identical across skills. Each skill keeps its own
# copy, not a symlink, because `npx skills add` drops symlinked files
# (Skills CLI 1.9.0, checked 2026-11-24). See AGENTS.md for how to recheck
# on a newer version.
SHARED = [
    [
        "omarchy-flatpak/templates/bin/pages.sh",
        "omarchy-arch-repo/templates/bin/pages.sh",
    ],
]


class SharedSkillFilesTests(unittest.TestCase):
    def test_copies_are_identical_regular_files(self):
        for group in SHARED:
            first, *rest = group
            for path in group:
                self.assertFalse((SKILLS / path).is_symlink(), f"{path} must be a regular file")
            for path in rest:
                with self.subTest(path=path):
                    self.assertEqual(
                        (SKILLS / first).read_bytes(),
                        (SKILLS / path).read_bytes(),
                        f"{path} differs from {first}; edit one, then copy it over the other",
                    )


if __name__ == "__main__":
    unittest.main()
