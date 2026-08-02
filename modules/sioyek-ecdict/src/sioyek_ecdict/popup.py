from __future__ import annotations

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Gdk", "4.0")
gi.require_version("Gtk4LayerShell", "1.0")
from gi.repository import Gdk, GLib, Gtk, Gtk4LayerShell  # noqa: E402

from .card import DictionaryCard
from .presentation import LookupPresentation

CSS = b"""
window.sioyek-dict-overlay, .sioyek-dict-overlay { background: transparent; }
.dictionary-card {
    background: rgba(30, 32, 38, 0.97);
    color: #f3f4f6;
    border: 1px solid rgba(255, 255, 255, 0.18);
    border-radius: 14px;
    box-shadow: 0 12px 36px rgba(0, 0, 0, 0.42);
    padding: 16px;
}
.dictionary-word { font-size: 22px; font-weight: 700; }
.dictionary-phonetic { color: #a7c7ff; font-size: 14px; }
.dictionary-meta { color: #aeb4bf; font-size: 12px; }
.dictionary-translation { font-size: 16px; }
.dictionary-hint { color: #8f96a3; font-size: 11px; }
.dictionary-close {
    background: transparent; border: 0; color: #aeb4bf;
    min-width: 26px; min-height: 26px; padding: 0;
}
.dictionary-close:hover { color: white; background: rgba(255,255,255,0.10); }
"""


class PopupOverlay(Gtk.ApplicationWindow):
    """Transparent layer surface with a movable card at the top-right.

    A stable default position avoids pointer-coordinate quirks on Wayland. The
    transparent remainder provides click-outside dismissal, and drag updates
    are coalesced to one layout change per display frame for smooth movement.
    """

    CARD_MIN_WIDTH = 390
    CARD_MIN_HEIGHT = 220
    EDGE_MARGIN = 12

    def __init__(self, application: Gtk.Application, content: LookupPresentation) -> None:
        """Create a monitor-sized transparent surface containing one result card."""
        super().__init__(application=application)
        self.add_css_class("sioyek-dict-overlay")
        self.set_decorated(False)
        self.set_title("Sioyek ECDICT")

        Gtk4LayerShell.init_for_window(self)
        Gtk4LayerShell.set_namespace(self, "sioyek-ecdict")
        Gtk4LayerShell.set_layer(self, Gtk4LayerShell.Layer.OVERLAY)
        Gtk4LayerShell.set_keyboard_mode(self, Gtk4LayerShell.KeyboardMode.ON_DEMAND)
        for edge in (
            Gtk4LayerShell.Edge.TOP,
            Gtk4LayerShell.Edge.RIGHT,
            Gtk4LayerShell.Edge.BOTTOM,
            Gtk4LayerShell.Edge.LEFT,
        ):
            Gtk4LayerShell.set_anchor(self, edge, True)

        self.fixed = Gtk.Fixed()
        self.fixed.add_css_class("sioyek-dict-overlay")
        self.set_child(self.fixed)
        self.card = DictionaryCard(content, self.close)
        self.fixed.put(self.card, 40, 40)
        self.card_x = 40.0
        self.card_y = 40.0
        self.positioned = False
        self.drag_origin = (0.0, 0.0)
        self.pending_drag: tuple[float, float] | None = None
        self.drag_tick_id = 0

        self._install_dismissal()
        self._install_dragging()
        GLib.timeout_add(50, self._position_top_right)


    def _install_dismissal(self) -> None:
        """Close on Escape or a click outside the opaque card."""
        outside_click = Gtk.GestureClick()
        outside_click.set_propagation_phase(Gtk.PropagationPhase.CAPTURE)
        outside_click.connect("pressed", self._close_when_outside)
        self.fixed.add_controller(outside_click)

        escape = Gtk.ShortcutController()
        escape.add_shortcut(
            Gtk.Shortcut.new(
                Gtk.KeyvalTrigger.new(Gdk.KEY_Escape, Gdk.ModifierType.NO_MODIFIER_MASK),
                Gtk.CallbackAction.new(lambda *_: self.close() or True),
            )
        )
        self.add_controller(escape)

    def _install_dragging(self) -> None:
        """Allow pointer dragging to reposition the result card."""
        drag = Gtk.GestureDrag()
        drag.connect("drag-begin", self._drag_begin)
        drag.connect("drag-update", self._drag_update)
        drag.connect("drag-end", self._drag_end)
        self.card.add_controller(drag)

    def _position_top_right(self) -> bool:
        """Place the card predictably at the monitor's top-right corner."""
        card_width = max(self.card.get_width(), self.CARD_MIN_WIDTH)
        if self.get_width() <= card_width + self.EDGE_MARGIN * 2:
            return GLib.SOURCE_CONTINUE
        self.positioned = True
        self._move_constrained(
            self.get_width() - card_width - self.EDGE_MARGIN,
            self.EDGE_MARGIN,
        )
        return GLib.SOURCE_REMOVE


    def _move_constrained(self, x: float, y: float) -> None:
        """Move the card without allowing it to leave the visible monitor."""
        card_width = max(self.card.get_width(), self.CARD_MIN_WIDTH)
        card_height = max(self.card.get_height(), self.CARD_MIN_HEIGHT)
        max_x = max(self.EDGE_MARGIN, self.get_width() - card_width - self.EDGE_MARGIN)
        max_y = max(self.EDGE_MARGIN, self.get_height() - card_height - self.EDGE_MARGIN)
        self.card_x = min(max(self.EDGE_MARGIN, x), max_x)
        self.card_y = min(max(self.EDGE_MARGIN, y), max_y)
        self.fixed.move(self.card, self.card_x, self.card_y)

    def _close_when_outside(self, _gesture, _press: int, x: float, y: float) -> None:
        """Dismiss only when the press lands outside the card allocation."""
        inside = (
            self.card_x <= x <= self.card_x + self.card.get_width()
            and self.card_y <= y <= self.card_y + self.card.get_height()
        )
        if not inside:
            self.close()

    def _drag_begin(self, _gesture, _x: float, _y: float) -> None:
        """Remember the card origin for relative drag updates."""
        self.drag_origin = (self.card_x, self.card_y)

    def _drag_update(self, _gesture, dx: float, dy: float) -> None:
        """Coalesce pointer events into one card move per rendered frame."""
        self.pending_drag = (self.drag_origin[0] + dx, self.drag_origin[1] + dy)
        if not self.drag_tick_id:
            self.drag_tick_id = self.add_tick_callback(self._apply_pending_drag)

    def _drag_end(self, _gesture, dx: float, dy: float) -> None:
        """Commit the final drag coordinates even when no frame follows."""
        self.pending_drag = (self.drag_origin[0] + dx, self.drag_origin[1] + dy)
        self._apply_pending_drag()

    def _apply_pending_drag(self, *_args) -> bool:
        """Apply the newest queued drag displacement and stop this frame hook."""
        if self.pending_drag is not None:
            self._move_constrained(*self.pending_drag)
            self.pending_drag = None
        self.drag_tick_id = 0
        return GLib.SOURCE_REMOVE


class DictionaryPopupApplication(Gtk.Application):
    def __init__(self, content: LookupPresentation) -> None:
        """Create the single-window GTK application for one lookup."""
        super().__init__(application_id="io.github.sioyek.ecdict.popup")
        self.content = content
        self.window: PopupOverlay | None = None

    def do_activate(self) -> None:
        """Load styling and present the Wayland overlay."""
        provider = Gtk.CssProvider()
        provider.load_from_data(CSS)
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )
        self.window = PopupOverlay(self, self.content)
        self.window.present()


def show_popup(content: LookupPresentation) -> int:
    """Run a popup application until the user dismisses it."""
    return DictionaryPopupApplication(content).run([])
