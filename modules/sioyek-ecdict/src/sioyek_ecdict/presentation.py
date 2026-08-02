from __future__ import annotations

from dataclasses import dataclass

from .dictionary import Entry


@dataclass(frozen=True, slots=True)
class LookupPresentation:
    """UI-ready lookup result, independent from the GTK implementation."""

    title: str
    phonetic: str
    metadata: str
    translation: str
    found: bool


def present_entry(selection: str, entry: Entry | None, suggestions: list[str]) -> LookupPresentation:
    """Convert a domain lookup into bounded, human-readable popup content."""
    if entry is None:
        message = "词典中没有找到该词。"
        if suggestions:
            message += "\n\n可能是：" + "、".join(suggestions)
        return LookupPresentation(selection or "未选择单词", "", "", message, False)

    metadata: list[str] = []
    if entry.matched_form and entry.matched_form.casefold() != entry.word.casefold():
        metadata.append(f"{entry.matched_form} → {entry.word}")
    if entry.pos:
        metadata.append(entry.pos)
    if entry.collins:
        metadata.append(f"Collins {entry.collins}★")
    if entry.oxford:
        metadata.append("Oxford 3000")
    if entry.frq:
        metadata.append(f"现代词频 #{entry.frq}")
    elif entry.bnc:
        metadata.append(f"BNC #{entry.bnc}")

    source = entry.translation.strip() or entry.definition.strip() or "没有可显示的释义"
    # ECDICT stores line breaks as the two characters "\\n" in many rows.
    # Normalize them here so every UI and CLI consumer gets readable senses.
    source = source.replace("\\n", "\n")
    lines = [line.strip() for line in source.splitlines() if line.strip()]
    return LookupPresentation(
        title=entry.word,
        phonetic=f"/{entry.phonetic}/" if entry.phonetic else "",
        metadata="  ·  ".join(metadata),
        translation="\n".join(lines[:10])[:1200],
        found=True,
    )
