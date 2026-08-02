from __future__ import annotations

import argparse
from pathlib import Path

from .dictionary import DEFAULT_DB, ECDICT_URL, Dictionary, import_ecdict, normalize_selection
from .integration import configure_sioyek
from .presentation import present_entry


def _parser() -> argparse.ArgumentParser:
    """Build the command-line interface shared by Sioyek and manual queries."""
    parser = argparse.ArgumentParser(
        prog="sioyek-ecdict",
        description="在 Sioyek 选词位置显示离线 ECDICT 释义",
    )
    parser.add_argument("--database", type=Path, default=DEFAULT_DB)
    commands = parser.add_subparsers(dest="command", required=True)

    lookup = commands.add_parser("lookup", help="查询单词")
    lookup.add_argument("text", nargs="*")
    lookup.add_argument("--popup", action="store_true")


    importer = commands.add_parser("import", help="下载或导入 ECDICT")
    importer.add_argument("source", nargs="?", default=ECDICT_URL)

    bootstrap = commands.add_parser(
        "bootstrap", help="首次导入词典并配置 Sioyek"
    )
    bootstrap.add_argument("source", nargs="?", default=ECDICT_URL)

    commands.add_parser("configure", help="配置 Sioyek 单键快捷查询")
    commands.add_parser("serve", help="运行常驻 D-Bus 查询服务")
    return parser


def _lookup(database: Path, selection: str, popup: bool) -> int:
    """Resolve one selection and display it as text or a graphical popup."""
    selection = normalize_selection(selection)
    # A custom Sioyek command can be pressed without a selection. Treat that
    # path as a no-op so an empty dictionary card never interrupts reading.
    if not selection:
        return 0
    entry, suggestions = Dictionary(database).lookup(selection)
    content = present_entry(selection, entry, suggestions)
    if popup:
        # Import GTK lazily: CLI lookup and dictionary import remain headless-testable.
        from .popup import show_popup

        return show_popup(content)
    print(content.title)
    if content.phonetic:
        print(content.phonetic)
    if content.metadata:
        print(content.metadata)
    print(content.translation)
    return 0 if entry else 1


def _import_database(source: str, database: Path) -> None:
    """Import one ECDICT source and report the indexed row counts."""
    entries, forms = import_ecdict(source, database)
    print(f"已导入 {entries} 个词条、{forms} 个词形：{database}")


def _configure(database: Path) -> int:
    """Write Sioyek integration files for one explicit database."""
    prefs, keys, unit, shortcut = configure_sioyek(database=database)
    print(f"已更新 {prefs}")
    print(f"已更新 {keys}")
    print(f"已启动 {unit}")
    print(f"重载 Sioyek 后，选中英文并按 {shortcut} 查询；联网搜索已禁用。")
    return 0


def _bootstrap(database: Path, source: str) -> int:
    """Create the database once, then idempotently refresh the integration."""
    if database.is_file():
        print(f"复用本地词典：{database}")
    else:
        _import_database(source, database)
    return _configure(database)


def main(argv: list[str] | None = None) -> int:
    """Dispatch a command and return a process exit status."""
    args = _parser().parse_args(argv)
    if args.command == "lookup":
        return _lookup(args.database, " ".join(args.text), args.popup)
    if args.command == "serve":
        # GTK is imported only by the resident process; setup and CLI queries
        # remain lightweight and usable in headless environments.
        from .service import serve

        return serve(args.database)
    if args.command == "import":
        _import_database(args.source, args.database)
        return 0
    if args.command == "configure":
        return _configure(args.database)
    if args.command == "bootstrap":
        return _bootstrap(args.database, args.source)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
