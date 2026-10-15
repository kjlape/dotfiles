"""Run with: python3 -m unittest discover -s tests -v"""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


class LinkSkillsTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.outside = Path(temporary.name).resolve()
        self.repo = self.outside / "dotfiles checkout"
        self.repo.mkdir()
        self.script = self.repo / "link-skills"
        shutil.copy2(Path(__file__).resolve().parents[1] / "link-skills", self.script)
        for name in ("pitch", "review", "worktree"):
            source = self.repo / "skills" / name
            source.mkdir(parents=True)
            (source / "SKILL.md").write_text(f"# {name}\n")
        (self.repo / "skills/pitch/asset.txt").write_text("supporting asset\n")

    def run_linker(self, *args, success=True):
        # Deliberately run outside the checkout to check repo-relative targets.
        result = subprocess.run(
            [str(self.script), *map(str, args)],
            cwd=self.outside,
            capture_output=True,
            text=True,
        )
        if success:
            self.assertEqual(result.returncode, 0, result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0)
            self.assertNotIn("Traceback", result.stderr)
        return result

    def assert_link(self, relative_target, name):
        link = self.repo / relative_target / name
        source = self.repo / "skills" / name
        self.assertTrue(link.is_symlink())
        self.assertFalse(Path(os.readlink(link)).is_absolute())
        self.assertEqual(link.resolve(), source.resolve())
        self.assertEqual((link / "SKILL.md").read_bytes(), (source / "SKILL.md").read_bytes())
        return link

    def test_separate_harness_selections_and_supporting_assets(self):
        claude = "stow-agent-skills/.claude/skills"
        pi = "stow-agent-skills/.pi/agent/skills"
        self.run_linker(claude, "pitch", "worktree")
        self.run_linker(pi, "review")
        for name in ("pitch", "worktree"):
            self.assert_link(claude, name)
        self.assert_link(pi, "review")
        self.assertEqual(os.readlink(self.repo / pi / "review"), "../../../../skills/review")
        self.assertEqual((self.repo / claude / "pitch/asset.txt").read_text(), "supporting asset\n")
        self.assertEqual({path.name for path in (self.repo / claude).iterdir()}, {"pitch", "worktree"})
        self.assertEqual({path.name for path in (self.repo / pi).iterdir()}, {"review"})
        self.assertFalse((self.repo / "stow-agent-skills/.agents").exists())

    @unittest.skipUnless(shutil.which("stow"), "GNU Stow is not installed")
    def test_stow_installs_and_removes_selected_links(self):
        self.run_linker("stow-agent-skills/.claude/skills", "pitch")
        self.run_linker("stow-agent-skills/.pi/agent/skills", "review")
        home = self.outside / "home"
        home.mkdir()
        command = ["stow", f"--dir={self.repo}", f"--target={home}"]
        for extra_args in ([], ["--restow"]):
            result = subprocess.run(command + extra_args + ["stow-agent-skills"], capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual((home / ".claude/skills/pitch").resolve(), self.repo / "skills/pitch")
            self.assertEqual((home / ".pi/agent/skills/review").resolve(), self.repo / "skills/review")
            self.assertFalse((home / ".claude/skills/review").exists())
            self.assertFalse((home / ".pi/agent/skills/pitch").exists())
        result = subprocess.run(command + ["--delete", "stow-agent-skills"], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(list(home.iterdir()), [])

    def test_reruns_and_duplicate_names_are_idempotent(self):
        self.run_linker("selected", "pitch", "pitch")
        link = self.assert_link("selected", "pitch")
        inode = link.lstat().st_ino
        result = self.run_linker("selected", "pitch")
        self.assertIn("unchanged", result.stdout)
        self.assertEqual(link.lstat().st_ino, inode)

    def test_relinks_old_shared_hop_and_broken_symlinks(self):
        target = self.repo / "selected"
        target.mkdir()
        (target / "pitch").symlink_to("../shared/pitch")
        self.run_linker("selected", "pitch")
        self.assert_link("selected", "pitch")
        self.assertEqual(os.readlink(target / "pitch"), "../skills/pitch")

    def test_relinks_directory_symlinks_without_writing_through_them(self):
        target = self.repo / "selected"
        target.mkdir()
        old_source = self.repo / "skills/review"
        (target / "pitch").symlink_to(old_source, target_is_directory=True)
        self.run_linker("selected", "pitch")
        self.assert_link("selected", "pitch")
        self.assertEqual({path.name for path in old_source.iterdir()}, {"SKILL.md"})

    def test_preserves_unmentioned_links(self):
        self.run_linker("selected", "pitch")
        self.run_linker("selected", "review")
        self.assert_link("selected", "pitch")
        self.assert_link("selected", "review")

    def test_preserves_existing_files_and_directories_without_partial_changes(self):
        for is_directory in (False, True):
            with self.subTest(directory=is_directory):
                target = self.repo / f"selected-{is_directory}"
                target.mkdir()
                conflict = target / "review"
                if is_directory:
                    conflict.mkdir()
                    (conflict / "keep.txt").write_text("keep")
                else:
                    conflict.write_text("keep")
                (target / "pitch").symlink_to("stale")
                result = self.run_linker(target, "pitch", "review", success=False)
                self.assertIn("refusing to replace", result.stderr)
                self.assertEqual(os.readlink(target / "pitch"), "stale")
                self.assertFalse(conflict.is_symlink())
                self.assertEqual((conflict / "keep.txt" if is_directory else conflict).read_text(), "keep")

    def test_unknown_or_incomplete_skills_do_not_create_target(self):
        (self.repo / "skills/incomplete").mkdir()
        for name in ("missing", "incomplete"):
            with self.subTest(name=name):
                self.run_linker("selected", "pitch", name, success=False)
                self.assertFalse((self.repo / "selected").exists())

    def test_rejects_paths_instead_of_skill_names(self):
        for name in ("", ".", "..", "../pitch", "/pitch", "pitch/asset.txt"):
            with self.subTest(name=name):
                self.run_linker("selected", name, success=False)
                self.assertFalse((self.repo / "selected").exists())

    def test_rejects_targets_outside_checkout(self):
        for target in ("../escape", self.outside / "escape"):
            with self.subTest(target=target):
                result = self.run_linker(target, "pitch", success=False)
                self.assertIn("inside this repository", result.stderr)
                self.assertFalse((self.outside / "escape").exists())

    def test_rejects_target_symlinks_that_escape_checkout(self):
        (self.repo / "escape").symlink_to(self.outside, target_is_directory=True)
        self.run_linker("escape/selected", "pitch", success=False)
        self.assertFalse((self.outside / "selected").exists())

    def test_rejects_targets_inside_skill_sources(self):
        for target in ("skills", "skills/pitch", "skills/new-directory"):
            with self.subTest(target=target):
                result = self.run_linker(target, "pitch", success=False)
                self.assertIn("skill sources", result.stderr)
        self.assertFalse((self.repo / "skills/new-directory").exists())

    def test_accepts_absolute_targets_and_spaces(self):
        target = self.repo / "stow-custom/.some agent/skills"
        self.run_linker(target, "pitch")
        self.assert_link(target, "pitch")

    def test_help_and_required_arguments(self):
        self.assertIn("target_dir", self.run_linker("--help").stdout)
        self.run_linker(success=False)
        self.run_linker("selected", success=False)
        self.assertFalse((self.repo / "selected").exists())


if __name__ == "__main__":
    unittest.main()
