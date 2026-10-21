"""Standalone skill smoke tests. Run: python3 -m unittest discover -s tests -v"""

import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


@unittest.skipUnless(shutil.which("node"), "Node.js 20+ is not installed")
class AdverseReviewPiTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name).resolve()
        # Copy only the skill, outside this checkout, like a Skills CLI install.
        self.skill = self.root / "installed skill"
        source = Path(__file__).resolve().parents[1] / "skills/adverse-review-pi"
        shutil.copytree(source, self.skill)
        self.target = self.root / "review target"
        self.target.mkdir()
        (self.target / "example.js").write_text("export const answer = 42;\n")

    def run_helper(self, name, *args, code=0):
        result = subprocess.run(
            ["node", str(self.skill / "scripts" / name), *map(str, args)],
            cwd=self.target,
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, code, result.stdout + result.stderr)
        return result

    def write_json(self, name, value):
        path = self.root / name
        path.write_text(json.dumps(value))
        return path

    def round1(self, persona, verdict="approve", findings=None):
        return self.write_json(
            f"round1-{persona}.json",
            {
                "persona": persona,
                "verdict": verdict,
                "summary": "Review complete.",
                "findings": findings or [],
            },
        )

    def test_bundles_prompts_and_license(self):
        for name in ("auditor", "adversary", "pragmatist", "round1", "round2"):
            prompt = self.skill / "scripts/prompts" / f"{name}.txt"
            self.assertTrue(prompt.is_file(), prompt)
            self.assertGreater(len(prompt.read_text()), 100)
        self.assertIn("MIT", (self.skill / "LICENSE").read_text())
        instructions = (self.skill / "SKILL.md").read_text()
        self.assertIn("`${SKILL_DIR}/scripts`", instructions)
        self.assertNotIn("${SKILL_DIR}/../adverse-review", instructions)

    def test_workflow_example_preserves_visible_parallel_reviewers(self):
        instructions = (self.skill / "SKILL.md").read_text()
        self.assertIn("`/agents → Workflows`", instructions)
        self.assertIn("`SubagentWorkflow` tool must be available", instructions)
        script = instructions.split("```javascript\n", 1)[1].split("```", 1)[0]
        # Execute the documented workflow with a stub host, not real models.
        harness = """
const calls = [];
const args = {reviewers: ['auditor', 'adversary', 'pragmatist'].map(
  persona => ({persona, prompt: persona}))};
const phase = title => calls.push({phase: title});
const parallel = thunks => Promise.all(thunks.map(fn => fn()));
const agent = async (prompt, options) => {
  calls.push({prompt, ...options});
  return prompt === 'adversary' ? null : '{"persona":"' + prompt + '"}';
};
"""
        executable = script.replace("export const meta =", "const meta =", 1)
        result = subprocess.run(
            ["node", "--input-type=module", "-e", harness
             + "const result = await (async () => {\n" + executable
             + "\n})();\nconsole.log(JSON.stringify({calls, result}));"],
            capture_output=True, text=True, check=True,
        )
        output = json.loads(result.stdout)
        reviewers = output["calls"][1:]
        self.assertEqual(len(reviewers), 3)
        self.assertEqual({r["label"] for r in reviewers},
                         {"r1:auditor", "r1:adversary", "r1:pragmatist"})
        for reviewer in reviewers:
            self.assertEqual(reviewer["phase"], "Independent reviews")
            self.assertEqual(reviewer["agentType"], "general-purpose")
        self.assertEqual(len(output["result"]["reviews"]), 3)
        self.assertIsNone(output["result"]["reviews"][1]["result"])

    def test_collects_source_without_upstream_checkout(self):
        source = self.root / "source.txt"
        files = self.root / "files.json"
        self.run_helper(
            "collect.mjs", "--target", self.target,
            "--out", source, "--files-out", files,
        )
        self.assertIn("export const answer = 42;", source.read_text())
        self.assertIn("example.js", files.read_text())
        json.loads(files.read_text())

    @unittest.skipUnless(shutil.which("git"), "Git is not installed")
    def test_collects_uncommitted_diff_and_branch_diff(self):
        def git(*args):
            subprocess.run(
                ["git", "-C", str(self.target), *args],
                check=True, capture_output=True, text=True,
            )

        git("init")
        git("add", "example.js")
        git("-c", "user.name=Test", "-c", "user.email=test@example.com",
            "commit", "-m", "Initial source")
        (self.target / "example.js").write_text("export const answer = 43;\n")
        source = self.root / "source.txt"
        self.run_helper(
            "collect.mjs", "--target", self.target, "--diff=", "--out", source,
        )
        self.assertIn("+export const answer = 43;", source.read_text())
        git("add", "example.js")
        git("-c", "user.name=Test", "-c", "user.email=test@example.com",
            "commit", "-m", "Change answer")
        self.run_helper(
            "collect.mjs", "--target", self.target, "--diff=HEAD~1", "--out", source,
        )
        self.assertIn("+export const answer = 43;", source.read_text())

    def test_missing_target_fails(self):
        result = self.run_helper(
            "collect.mjs", "--target", self.root / "missing",
            "--out", self.root / "source.txt", code=1,
        )
        self.assertTrue(result.stderr.strip())

    def test_synthesizes_reports_with_cross_review(self):
        round1 = self.root / "round1.json"
        self.run_helper(
            "combine.mjs", "--round1", self.round1("auditor"),
            self.round1("pragmatist"), "--out", round1,
        )
        cross_reviews = [
            self.write_json(
                f"round2-{persona}.json",
                {"persona": persona, "validate": [], "challenge": [], "added": []},
            )
            for persona in ("auditor", "pragmatist")
        ]
        round2 = self.root / "round2.json"
        self.run_helper("combine.mjs", "--round2", *cross_reviews, "--out", round2)
        markdown = self.root / "report.md"
        report = self.root / "report.json"
        html = self.root / "report.html"
        self.run_helper(
            "synthesize.mjs", "--round1", round1, "--round2", round2,
            "--out", markdown, "--json-out", report, "--html-out", html,
        )
        self.assertIn("SHIP", markdown.read_text())
        json.loads(report.read_text())
        self.assertIn("<html", html.read_text().lower())

    def test_block_writes_reports_and_exits_one_without_round2(self):
        finding = {
            "severity": "critical",
            "file": "example.js",
            "line": 1,
            "title": "Unsafe execution",
            "detail": "User input is executed as code without validation.",
            "fix": "Remove dynamic execution.",
        }
        round1 = self.root / "round1.json"
        self.run_helper(
            "combine.mjs", "--round1", self.round1("auditor", "reject", [finding]),
            self.round1("adversary", "reject", [finding]), "--out", round1,
        )
        markdown = self.root / "report.md"
        report = self.root / "report.json"
        html = self.root / "report.html"
        self.run_helper(
            "synthesize.mjs", "--round1", round1, "--out", markdown,
            "--json-out", report, "--html-out", html, code=1,
        )
        self.assertIn("BLOCK", markdown.read_text())
        self.assertIn("Unsafe execution", markdown.read_text())
        json.loads(report.read_text())
        self.assertIn("<html", html.read_text().lower())


if __name__ == "__main__":
    unittest.main()
