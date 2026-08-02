from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from sioyek_ecdict.dictionary import Dictionary, import_ecdict, normalize_selection

CSV = """word,phonetic,definition,translation,pos,collins,oxford,tag,bnc,frq,exchange,detail,audio
dependency,dɪˈpendənsi,dependence,依赖；依赖关系,n.,3,1,cet6,5000,4000,p:dependencies,,
study,ˈstʌdi,learn,学习；研究,v.,4,1,cet4,1000,800,p:studies/d:studied/i:studying,,
run,rʌn,move quickly,跑；运行,v.,5,1,cet4,300,200,i:running/d:ran,,
"""


class DictionaryTest(unittest.TestCase):
    def setUp(self) -> None:
        """Create an isolated imported dictionary for each test."""
        self.directory = tempfile.TemporaryDirectory()
        root = Path(self.directory.name)
        self.csv = root / "fixture.csv"
        self.csv.write_text(CSV, encoding="utf-8")
        self.database = root / "dictionary.sqlite3"
        import_ecdict(str(self.csv), self.database)
        self.dictionary = Dictionary(self.database)

    def tearDown(self) -> None:
        """Release the temporary dictionary directory."""
        self.directory.cleanup()

    def test_normalizes_pdf_line_break_hyphen(self) -> None:
        """PDF line-end hyphens are removed before lookup."""
        self.assertEqual(normalize_selection("  depen-\ndency, "), "dependency")

    def test_exact_lookup(self) -> None:
        """Exact words preserve their ECDICT definition."""
        entry, suggestions = self.dictionary.lookup("dependency")
        self.assertEqual(entry.word, "dependency")
        self.assertIn("依赖", entry.translation)
        self.assertEqual(suggestions, [])

    def test_exchange_form_returns_lemma(self) -> None:
        """ECDICT exchange forms resolve to their lemma."""
        entry, _ = self.dictionary.lookup("studied")
        self.assertEqual(entry.word, "study")
        self.assertEqual(entry.matched_form, "studied")

    def test_morphology_fallback_handles_plural(self) -> None:
        """Simple fallback morphology works without a heavy NLP model."""
        entry, _ = self.dictionary.lookup("dependencies")
        self.assertEqual(entry.word, "dependency")

    def test_unknown_word_returns_ranked_prefixes(self) -> None:
        """Unknown prefixes return useful candidates."""
        entry, suggestions = self.dictionary.lookup("stu")
        self.assertIsNone(entry)
        self.assertEqual(suggestions, ["study"])


if __name__ == "__main__":
    unittest.main()
