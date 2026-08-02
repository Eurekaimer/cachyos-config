from __future__ import annotations

import csv
import os
import re
import sqlite3
import tempfile
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

ECDICT_URL = "https://raw.githubusercontent.com/skywind3000/ECDICT/master/ecdict.csv"
DATA_HOME = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share"))
DEFAULT_DB = DATA_HOME / "sioyek-ecdict/ecdict.sqlite3"


@dataclass(frozen=True, slots=True)
class Entry:
    word: str
    phonetic: str
    translation: str
    definition: str
    pos: str
    collins: int
    oxford: bool
    tag: str
    bnc: int
    frq: int
    matched_form: str = ""


def normalize_selection(text: str) -> str:
    """Remove PDF selection artifacts while preserving phrases."""
    text = text.replace("\u00ad", "")
    text = re.sub(r"(?<=[A-Za-z])-\s+(?=[A-Za-z])", "", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text.strip(" \t\r\n\"'‘’“”.,;:!?()[]{}<>«»")


def _variants(word: str) -> list[str]:
    """Generate conservative English inflection candidates for fallback lookup."""
    result: list[str] = []

    def add(candidate: str) -> None:
        """Append one unique, non-trivial candidate."""
        if len(candidate) >= 2 and candidate not in result:
            result.append(candidate)

    lower = word.casefold()
    if lower.endswith("'s"):
        add(lower[:-2])
    if lower.endswith("ies") and len(lower) > 4:
        add(lower[:-3] + "y")
    if lower.endswith("ves") and len(lower) > 4:
        add(lower[:-3] + "f")
        add(lower[:-3] + "fe")
    if lower.endswith("es") and len(lower) > 3:
        add(lower[:-2])
        add(lower[:-1])
    if lower.endswith("s") and not lower.endswith("ss") and len(lower) > 3:
        add(lower[:-1])
    if lower.endswith("ied") and len(lower) > 4:
        add(lower[:-3] + "y")
    if lower.endswith("ed") and len(lower) > 3:
        stem = lower[:-2]
        add(stem)
        add(stem + "e")
        if len(stem) > 2 and stem[-1] == stem[-2]:
            add(stem[:-1])
    if lower.endswith("ing") and len(lower) > 5:
        stem = lower[:-3]
        add(stem)
        add(stem + "e")
        if len(stem) > 2 and stem[-1] == stem[-2]:
            add(stem[:-1])
    return result


class Dictionary:
    def __init__(self, path: Path = DEFAULT_DB) -> None:
        """Create a reader for the given SQLite dictionary."""
        self.path = path

    def connect(self) -> sqlite3.Connection:
        """Open the dictionary read-only so lookups cannot mutate imported data."""
        if not self.path.exists():
            raise FileNotFoundError(
                f"词典尚未安装：{self.path}\n请运行 sioyek-ecdict import"
            )
        connection = sqlite3.connect(f"file:{self.path}?mode=ro", uri=True)
        connection.row_factory = sqlite3.Row
        return connection

    @staticmethod
    def _entry(row: sqlite3.Row, matched_form: str = "") -> Entry:
        """Convert one SQLite row into the stable domain model."""
        return Entry(
            word=row["word"],
            phonetic=row["phonetic"] or "",
            translation=row["translation"] or "",
            definition=row["definition"] or "",
            pos=row["pos"] or "",
            collins=row["collins"] or 0,
            oxford=bool(row["oxford"]),
            tag=row["tag"] or "",
            bnc=row["bnc"] or 0,
            frq=row["frq"] or 0,
            matched_form=matched_form,
        )

    def lookup(self, selection: str) -> tuple[Entry | None, list[str]]:
        """Find an exact word, known inflection, lemma fallback, or suggestions."""
        query = normalize_selection(selection)
        if not query:
            return None, []
        with self.connect() as connection:
            row = connection.execute(
                "SELECT * FROM entries WHERE word = ? COLLATE NOCASE", (query,)
            ).fetchone()
            if row:
                return self._entry(row), []

            form = connection.execute(
                """
                SELECT e.* FROM forms f
                JOIN entries e ON e.word = f.word
                WHERE f.form = ? COLLATE NOCASE
                ORDER BY CASE WHEN e.frq > 0 THEN e.frq ELSE 2147483647 END
                LIMIT 1
                """,
                (query,),
            ).fetchone()
            if form:
                return self._entry(form, query), []

            for variant in _variants(query):
                row = connection.execute(
                    "SELECT * FROM entries WHERE word = ? COLLATE NOCASE", (variant,)
                ).fetchone()
                if row:
                    return self._entry(row, query), []

            suggestions = [
                item[0]
                for item in connection.execute(
                    """
                    SELECT word FROM entries
                    WHERE word LIKE ? ESCAPE '\\'
                    ORDER BY CASE WHEN frq > 0 THEN frq ELSE 2147483647 END,
                             CASE WHEN bnc > 0 THEN bnc ELSE 2147483647 END,
                             length(word)
                    LIMIT 6
                    """,
                    (_like_prefix(query),),
                )
            ]
            return None, suggestions


def _like_prefix(text: str) -> str:
    """Escape SQL LIKE metacharacters and produce a prefix pattern."""
    return text.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_") + "%"


def _integer(value: str | None) -> int:
    """Parse optional numeric CSV fields without aborting an import."""
    try:
        return int(value or 0)
    except ValueError:
        return 0


def _exchange_forms(exchange: str) -> Iterable[tuple[str, str]]:
    """Yield normalized inflected forms from ECDICT's exchange column."""
    for part in exchange.split("/"):
        if ":" not in part:
            continue
        kind, values = part.split(":", 1)
        for value in values.split(","):
            form = normalize_selection(value)
            if form:
                yield form.casefold(), kind


def import_ecdict(source: str, destination: Path = DEFAULT_DB) -> tuple[int, int]:
    """Atomically import an ECDICT CSV file or URL into indexed SQLite."""
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary_download: Path | None = None
    source_path = Path(source).expanduser()
    if source.startswith(("https://", "http://")):
        with tempfile.NamedTemporaryFile(prefix="ecdict-", suffix=".csv", delete=False) as output:
            temporary_download = Path(output.name)
            with urllib.request.urlopen(source, timeout=60) as response:
                while chunk := response.read(1024 * 1024):
                    output.write(chunk)
        source_path = temporary_download

    temporary_db = destination.with_suffix(".sqlite3.tmp")
    temporary_db.unlink(missing_ok=True)
    entries = 0
    forms = 0
    try:
        connection = sqlite3.connect(temporary_db)
        connection.executescript(
            """
            PRAGMA journal_mode = OFF;
            PRAGMA synchronous = OFF;
            CREATE TABLE entries (
                word TEXT PRIMARY KEY COLLATE NOCASE,
                phonetic TEXT NOT NULL DEFAULT '',
                definition TEXT NOT NULL DEFAULT '',
                translation TEXT NOT NULL DEFAULT '',
                pos TEXT NOT NULL DEFAULT '',
                collins INTEGER NOT NULL DEFAULT 0,
                oxford INTEGER NOT NULL DEFAULT 0,
                tag TEXT NOT NULL DEFAULT '',
                bnc INTEGER NOT NULL DEFAULT 0,
                frq INTEGER NOT NULL DEFAULT 0
            ) WITHOUT ROWID;
            CREATE TABLE forms (
                form TEXT COLLATE NOCASE,
                word TEXT COLLATE NOCASE,
                kind TEXT,
                PRIMARY KEY (form, word)
            ) WITHOUT ROWID;
            """
        )
        with source_path.open("r", encoding="utf-8-sig", newline="") as stream:
            reader = csv.DictReader(stream)
            for row in reader:
                word = normalize_selection(row.get("word", ""))
                if not word:
                    continue
                connection.execute(
                    """
                    INSERT OR REPLACE INTO entries
                    (word, phonetic, definition, translation, pos, collins, oxford, tag, bnc, frq)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    (
                        word,
                        row.get("phonetic", ""),
                        row.get("definition", ""),
                        row.get("translation", ""),
                        row.get("pos", ""),
                        _integer(row.get("collins")),
                        _integer(row.get("oxford")),
                        row.get("tag", ""),
                        _integer(row.get("bnc")),
                        _integer(row.get("frq")),
                    ),
                )
                entries += 1
                for form, kind in _exchange_forms(row.get("exchange", "")):
                    connection.execute(
                        "INSERT OR IGNORE INTO forms (form, word, kind) VALUES (?, ?, ?)",
                        (form, word, kind),
                    )
                    forms += 1
                if entries % 10_000 == 0:
                    connection.commit()
        connection.executescript(
            """
            CREATE INDEX forms_form_index ON forms(form COLLATE NOCASE);
            CREATE INDEX entries_frequency_index ON entries(frq, bnc);
            ANALYZE;
            """
        )
        connection.commit()
        connection.close()
        temporary_db.replace(destination)
    finally:
        if temporary_download:
            temporary_download.unlink(missing_ok=True)
        temporary_db.unlink(missing_ok=True)
    return entries, forms
