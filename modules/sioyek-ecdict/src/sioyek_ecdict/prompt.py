from __future__ import annotations

from collections.abc import Callable

import gi

gi.require_version("Gdk", "4.0")
gi.require_version("Gtk", "4.0")
gi.require_version("Gtk4LayerShell", "1.0")
from gi.repository import Gdk, GLib, Gtk, Gtk4LayerShell  # noqa: E402


class DictionaryPrompt(Gtk.ApplicationWindow):
    """Keyboard-focused global dictionary prompt opened by Super+S."""

    def __init__(self, application: Gtk.Application, submit: Callable[[str], None]) -> None:
        """Build a centered prompt and retain the lookup callback."""
        super().__init__(application=application)
        self.submit = submit
        self.set_decorated(False)
        self.add_css_class("sioyek-dict-overlay")

        Gtk4LayerShell.init_for_window(self)
        Gtk4LayerShell.set_namespace(self, "sioyek-ecdict-prompt")
        Gtk4LayerShell.set_layer(self, Gtk4LayerShell.Layer.OVERLAY)
        Gtk4LayerShell.set_keyboard_mode(self, Gtk4LayerShell.KeyboardMode.EXCLUSIVE)
        for edge in Gtk4LayerShell.Edge.TOP, Gtk4LayerShell.Edge.RIGHT, Gtk4LayerShell.Edge.BOTTOM, Gtk4LayerShell.Edge.LEFT:
            Gtk4LayerShell.set_anchor(self, edge, True)

        self.fixed = Gtk.Fixed()
        self.fixed.add_css_class("sioyek-dict-overlay")
        self.set_child(self.fixed)
        self.card = self._build_card()
        self.fixed.put(self.card, 0, 0)
        self._install_dismissal()
        GLib.timeout_add(50, self._center_card)

    def _build_card(self) -> Gtk.Widget:
        """Build the compact search field and usage hint."""
        card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        card.add_css_class("dictionary-card")
        card.set_size_request(520, -1)
        title = Gtk.Label(label="ECDICT 英汉词典", xalign=0)
        title.add_css_class("dictionary-word")
        card.append(title)
        self.entry = Gtk.SearchEntry(placeholder_text="输入英文单词或短语…")
        self.entry.set_hexpand(True)
        self.entry.connect("activate", self._submit)
        card.append(self.entry)
        hint = Gtk.Label(label="Enter 查询 · Esc 或点击外部关闭", xalign=0)
        hint.add_css_class("dictionary-hint")
        card.append(hint)
        return card

    def _install_dismissal(self) -> None:
        """Install Escape and outside-click dismissal handlers."""
        escape = Gtk.ShortcutController()
        escape.add_shortcut(
            Gtk.Shortcut.new(
                Gtk.KeyvalTrigger.new(Gdk.KEY_Escape, Gdk.ModifierType.NO_MODIFIER_MASK),
                Gtk.CallbackAction.new(lambda *_: self.close() or True),
            )
        )
        self.add_controller(escape)
        click = Gtk.GestureClick()
        click.set_propagation_phase(Gtk.PropagationPhase.CAPTURE)
        click.connect("pressed", self._close_when_outside)
        self.fixed.add_controller(click)

    def _center_card(self) -> bool:
        """Center the card after layer-shell reports the monitor allocation."""
        card_width = max(520, self.card.get_width())
        if self.get_width() <= card_width + 24:
            return GLib.SOURCE_CONTINUE
        x = (self.get_width() - card_width) / 2
        y = max(12, self.get_height() * 0.30)
        self.fixed.move(self.card, x, y)
        self.entry.grab_focus()
        return GLib.SOURCE_REMOVE

    def _close_when_outside(self, _gesture, _press: int, x: float, y: float) -> None:
        """Close when a pointer press misses the centered card."""
        allocation = self.card.get_allocation()
        inside = (
            allocation.x <= x <= allocation.x + allocation.width
            and allocation.y <= y <= allocation.y + allocation.height
        )
        if not inside:
            self.close()

    def _submit(self, _entry: Gtk.SearchEntry) -> None:
        """Close the prompt and request a lookup for non-empty input."""
        text = self.entry.get_text().strip()
        self.close()
        if text:
            self.submit(text)
