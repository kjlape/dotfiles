"""Run with: python3 -m unittest discover -s tests -v"""

from pathlib import Path
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]
SHELL_FILES = (
    "stow-bash/.bashrc",
    "stow-bash/.bash_profile",
    "stow-shell-config/.env",
    "stow-shell-config/.me",
    "brew.sh",
)
FORBIDDEN_STDERR = (
    "No such file or directory",
    "command not found",
    "syntax error",
)


class ShellStartupTests(unittest.TestCase):
    def test_syntax(self):
        for name in SHELL_FILES:
            with self.subTest(name=name):
                result = subprocess.run(
                    ["bash", "-n", str(REPO / name)],
                    capture_output=True,
                    text=True,
                )
                self.assertEqual(result.returncode, 0, result.stderr)

    def make_home(self, omarchy):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        root = Path(temporary.name).resolve()
        home = root / "home"
        home.mkdir()
        for name in (".bashrc", ".bash_profile", ".env", ".me"):
            source = {
                ".bashrc": REPO / "stow-bash/.bashrc",
                ".bash_profile": REPO / "stow-bash/.bash_profile",
                ".env": REPO / "stow-shell-config/.env",
                ".me": REPO / "stow-shell-config/.me",
            }[name]
            (home / name).write_text(source.read_text())
        bashrc = home / ".bashrc"
        text = bashrc.read_text()
        text = text.replace("/etc/omarchy.conf", str(root / "etc/omarchy.conf"))
        text = text.replace("/usr/share/omarchy", str(root / "omarchy"))
        bashrc.write_text(text)
        if omarchy:
            rc = root / "omarchy/default/bash/rc"
            rc.parent.mkdir(parents=True)
            rc.write_text("echo OMARCHY_RC_LOADED\n")
        return home

    def start_shell(self, omarchy):
        home = self.make_home(omarchy)
        return subprocess.run(
            ["bash", "-l", "-i", "-c", "echo STARTUP_OK"],
            env={"HOME": str(home), "PATH": "/usr/bin:/bin", "TERM": "dumb"},
            cwd=home,
            stdin=subprocess.DEVNULL,
            capture_output=True,
            text=True,
            timeout=20,
        )

    def assert_starts(self, result, omarchy):
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("STARTUP_OK", result.stdout)
        if omarchy:
            self.assertIn("OMARCHY_RC_LOADED", result.stdout)
        else:
            self.assertNotIn("OMARCHY_RC_LOADED", result.stdout)
        for text in FORBIDDEN_STDERR:
            self.assertNotIn(text, result.stderr)

    def test_starts_with_omarchy(self):
        self.assert_starts(self.start_shell(omarchy=True), omarchy=True)

    def test_starts_without_omarchy(self):
        self.assert_starts(self.start_shell(omarchy=False), omarchy=False)
