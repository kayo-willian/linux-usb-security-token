"""Verify local Markdown links without using the network or host PAM."""
from pathlib import Path
import re
import unittest
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[1]
LINK = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")


class DocumentationLinkTests(unittest.TestCase):
    def test_local_targets_exist(self):
        for document in sorted(ROOT.rglob("*.md")):
            with self.subTest(document=str(document.relative_to(ROOT))):
                content = document.read_text(encoding="utf-8")
                for href in LINK.findall(content):
                    if href.startswith(("https://", "http://", "mailto:", "#")):
                        continue
                    relative = unquote(href.split("#", 1)[0])
                    if not relative:
                        continue
                    target = (document.parent / relative).resolve()
                    self.assertTrue(target.is_relative_to(ROOT), f"Link escapes repository: {href}")
                    self.assertTrue(target.exists(), f"Broken link in {document}: {href}")


if __name__ == "__main__":
    unittest.main()
