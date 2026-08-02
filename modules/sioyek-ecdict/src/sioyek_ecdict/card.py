from __future__ import annotations

import gi

gi.require_version("Gtk", "4.0")
from gi.repository import Gtk  # noqa: E402

from .presentation import LookupPresentation


class DictionaryCard(Gtk.Box):
    """Movable visual card; window placement and dismissal live in the overlay."""

    def __init__(self, content: LookupPresentation, close_callback) -> None:
        """Build a compact, selectable dictionary result card."""
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=9)
        self.add_css_class("dictionary-card")
        self.set_size_request(390, -1)

        header = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        title = Gtk.Label(label=content.title, xalign=0, ellipsize=3)
        title.add_css_class("dictionary-word")
        title.set_hexpand(True)
        close = Gtk.Button(label="×", tooltip_text="关闭（Esc）")
        close.add_css_class("dictionary-close")
        close.connect("clicked", lambda *_: close_callback())
        header.append(title)
        header.append(close)
        self.append(header)

        if content.phonetic:
            phonetic = Gtk.Label(label=content.phonetic, xalign=0)
            phonetic.add_css_class("dictionary-phonetic")
            self.append(phonetic)
        if content.metadata:
            metadata = Gtk.Label(label=content.metadata, xalign=0, wrap=True)
            metadata.add_css_class("dictionary-meta")
            self.append(metadata)

        self.append(Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL))
        translation = Gtk.Label(
            label=content.translation,
            xalign=0,
            yalign=0,
            wrap=True,
            selectable=True,
            max_width_chars=52,
        )
        translation.add_css_class("dictionary-translation")
        scroller = Gtk.ScrolledWindow()
        scroller.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        scroller.set_max_content_height(360)
        scroller.set_propagate_natural_height(True)
        scroller.set_child(translation)
        self.append(scroller)

        hint = Gtk.Label(label="拖动卡片可移动 · 点击卡片外或按 Esc 关闭", xalign=0)
        hint.add_css_class("dictionary-hint")
        self.append(hint)
