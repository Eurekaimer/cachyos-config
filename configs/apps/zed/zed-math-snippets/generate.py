#!/usr/bin/env python3
"""从 modules/*.toml 生成 Zed snippets（markdown/latex/typst），可选安装。

只用 Python 标准库；需要 Python 3.11+（tomllib）。
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import sys
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DIST = ROOT / "dist"
MODULES = [
    "greek",
    "symbols",
    "operators",
    "algebra",
    "calculus",
    "linear_algebra",
    "probability",
    "templates",
]
LANGS = ("markdown", "latex", "typst")
ALLOWED_FIELDS = {"prefix", "latex", "typst", "markdown", "description", "langs"}


class BuildError(Exception):
    """配置或 snippet body 不合法。"""


def parse_body(body: str) -> list[int]:
    """按 Zed 的 snippet 语法做最小解析，返回出现的 tabstop 编号。

    规则与 crates/snippet/src/snippet.rs 一致：`\\$`、`\\\\`、`\\}` 是转义；
    其它反斜杠按字面保留；`$` 后必须是数字或 `{`。
    """
    stops: list[int] = []
    i = 0
    n = len(body)
    while i < n:
        char = body[i]
        if char == "\\":
            if i + 1 < n and body[i + 1] in "$\\}":
                i += 2
            else:
                i += 1
            continue
        if char != "$":
            i += 1
            continue
        if i + 1 < n and body[i + 1] == "{":
            number = re.match(r"\d+", body[i + 2 :])
            if number is None:
                raise BuildError("占位符 ${...} 缺少编号")
            stops.append(int(number.group()))
            j = i + 2 + len(number.group())
            depth = 1
            while j < n:
                current = body[j]
                if current == "\\":
                    j += 2
                    continue
                if current == "$" and body[j : j + 2] == "${":
                    depth += 1
                    j += 2
                    continue
                if current == "}":
                    depth -= 1
                    if depth == 0:
                        j += 1
                        break
                j += 1
            if depth != 0:
                raise BuildError("占位符缺少配对的 }")
            i = j
            continue
        if i + 1 < n and body[i + 1].isdigit():
            number = re.match(r"\d+", body[i + 1 :])
            assert number is not None
            stops.append(int(number.group()))
            i += 1 + len(number.group())
            continue
        raise BuildError("字面量 $ 必须写成 \\$")
    if 0 not in stops:
        raise BuildError("body 缺少 $0 最终跳转位置")
    return stops


def load_module(module: str) -> list[dict]:
    path = ROOT / "modules" / f"{module}.toml"
    try:
        data = tomllib.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise BuildError(f"缺少模块文件 {path}") from exc
    except tomllib.TOMLDecodeError as exc:
        raise BuildError(f"{path.name}: TOML 解析失败: {exc}") from exc

    unknown = set(data) - {"snippet"}
    if unknown:
        raise BuildError(f"{path.name}: 未知顶层字段 {sorted(unknown)}")
    snippets = data.get("snippet")
    if not isinstance(snippets, list) or not snippets:
        raise BuildError(f"{path.name}: 需要至少一个 [[snippet]]")

    result = []
    for index, item in enumerate(snippets, 1):
        where = f"{path.name} 第 {index} 条"
        if not isinstance(item, dict):
            raise BuildError(f"{where}: 必须是表")
        unknown = set(item) - ALLOWED_FIELDS
        if unknown:
            raise BuildError(f"{where}: 未知字段 {sorted(unknown)}")
        for field in ("prefix", "latex", "description"):
            if not isinstance(item.get(field), str) or not item[field].strip():
                raise BuildError(f"{where}: 缺少非空字符串字段 {field}")
        prefix = item["prefix"]
        if any(char.isspace() for char in prefix):
            raise BuildError(f"{where}: prefix 不能包含空白")
        langs = item.get("langs", list(LANGS))
        if not isinstance(langs, list) or not langs:
            raise BuildError(f"{where}: langs 必须是非空列表")
        if any(lang not in LANGS for lang in langs):
            raise BuildError(f"{where}: langs 只能包含 {LANGS}")
        if len(set(langs)) != len(langs):
            raise BuildError(f"{where}: langs 有重复项")
        if "typst" in langs and not isinstance(item.get("typst"), str):
            raise BuildError(f"{where}: langs 含 typst 时必须提供 typst")
        for field in ("latex", "typst", "markdown"):
            if field in item and not isinstance(item[field], str):
                raise BuildError(f"{where}: {field} 必须是字符串")
        for field in ("latex", "typst", "markdown"):
            if field in item:
                try:
                    parse_body(item[field])
                except BuildError as exc:
                    raise BuildError(f"{where} ({prefix}) 的 {field}: {exc}") from exc
        result.append(item)
    return result


def build() -> tuple[dict[str, dict], dict[str, int]]:
    seen: dict[str, str] = {}
    outputs: dict[str, dict] = {lang: {} for lang in LANGS}
    counts: dict[str, int] = {}

    for module in MODULES:
        snippets = load_module(module)
        counts[module] = len(snippets)
        for item in snippets:
            prefix = item["prefix"]
            if prefix in seen:
                raise BuildError(f"prefix 重复: {prefix}（{seen[prefix]} 与 {module}）")
            seen[prefix] = module
            langs = item.get("langs", LANGS)
            for lang in langs:
                if lang == "markdown":
                    body = item.get("markdown", item["latex"])
                elif lang == "latex":
                    body = item["latex"]
                else:
                    body = item["typst"]
                outputs[lang][f"{module}/{prefix}"] = {
                    "prefix": prefix,
                    "body": body,
                    "description": item["description"],
                }
    return outputs, counts


def write_dist(outputs: dict[str, dict]) -> list[Path]:
    DIST.mkdir(exist_ok=True)
    written = []
    for lang in LANGS:
        path = DIST / f"{lang}.json"
        text = json.dumps(outputs[lang], ensure_ascii=False, indent=2) + "\n"
        path.write_text(text, encoding="utf-8")
        written.append(path)
    return written


def install(files: list[Path]) -> None:
    destination = Path.home() / ".config" / "zed" / "snippets"
    destination.mkdir(parents=True, exist_ok=True)
    existing = [destination / path.name for path in files if (destination / path.name).exists()]
    if existing:
        backup = Path.home() / ".config" / "zed" / "snippets-backup"
        shutil.rmtree(backup, ignore_errors=True)
        backup.mkdir(parents=True)
        for path in existing:
            shutil.copy2(path, backup / path.name)
        print(f"已备份 {len(existing)} 个旧文件到 {backup}")
    for path in files:
        shutil.copy2(path, destination / path.name)
    print(f"已安装到 {destination}")


def main() -> int:
    parser = argparse.ArgumentParser(description="生成 Zed 数学 snippets")
    parser.add_argument("--install", action="store_true", help="生成后复制到 ~/.config/zed/snippets")
    args = parser.parse_args()

    try:
        outputs, counts = build()
        files = write_dist(outputs)
    except BuildError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1

    total = sum(counts.values())
    width = max(len(name) for name in counts)
    for module in MODULES:
        print(f"{module:<{width}}  {counts[module]:>3}")
    print(f"{'total':<{width}}  {total:>3}")
    print("生成: " + ", ".join(str(path.relative_to(ROOT)) for path in files))
    for lang in LANGS:
        print(f"  {lang}: {len(outputs[lang])} 条")

    if args.install:
        install(files)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
