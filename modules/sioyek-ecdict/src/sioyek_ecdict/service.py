from __future__ import annotations

import gi
from pathlib import Path

gi.require_version("Gio", "2.0")
gi.require_version("GLib", "2.0")
gi.require_version("Gtk", "4.0")
gi.require_version("Gdk", "4.0")
from gi.repository import Gdk, Gio, GLib, Gtk  # noqa: E402

from .dictionary import DEFAULT_DB, Dictionary, normalize_selection
from .popup import CSS, PopupOverlay
from .prompt import DictionaryPrompt
from .presentation import present_entry

BUS_NAME = "io.github.sioyek.ecdict"
OBJECT_PATH = "/io/github/sioyek/ecdict"
INTERFACE_XML = """
<node>
  <interface name="io.github.sioyek.ecdict">
    <method name="Lookup">
      <arg type="s" name="selection" direction="in"/>
    </method>
    <method name="Prompt"/>
  </interface>
</node>
"""


class LookupService(Gtk.Application):
    """Warm GTK/SQLite process serving low-latency lookup requests over D-Bus."""

    def __init__(self, database: Path = DEFAULT_DB) -> None:
        """Create the hidden service for one explicit SQLite database."""
        super().__init__(application_id=BUS_NAME)
        self.dictionary = Dictionary(database)
        self.window: Gtk.ApplicationWindow | None = None
        self.registration_id = 0
        self.node_info = Gio.DBusNodeInfo.new_for_xml(INTERFACE_XML)

    def do_startup(self) -> None:
        """Register the lookup object and keep the application resident."""
        Gtk.Application.do_startup(self)
        provider = Gtk.CssProvider()
        provider.load_from_data(CSS)
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )
        connection = self.get_dbus_connection()
        self.registration_id = connection.register_object(
            OBJECT_PATH,
            self.node_info.interfaces[0],
            self._handle_method_call,
            None,
            None,
        )
        self.hold()

    def do_activate(self) -> None:
        """Remain hidden when systemd starts the service without a lookup."""

    def _handle_method_call(
        self,
        _connection,
        _sender,
        _object_path,
        _interface_name,
        method_name,
        parameters,
        invocation,
    ) -> None:
        """Resolve a D-Bus lookup or prompt request on the GTK main thread."""
        if method_name == "Prompt":
            invocation.return_value(GLib.Variant("()", ()))
            self._show_prompt()
            return
        if method_name == "Lookup":
            invocation.return_value(GLib.Variant("()", ()))
            self._show_lookup(parameters.unpack()[0])
            return
        invocation.return_dbus_error(BUS_NAME + ".Error", "Unknown method")


    def _replace_window(self, window: Gtk.ApplicationWindow) -> None:
        """Close the previous overlay before presenting its replacement."""
        if self.window:
            self.window.close()
        self.window = window
        self.window.present()

    def _show_lookup(self, raw_selection: str) -> None:
        """Normalize selected or typed text and present its dictionary result."""
        selection = normalize_selection(raw_selection)
        if not selection:
            return
        entry, suggestions = self.dictionary.lookup(selection)
        content = present_entry(selection, entry, suggestions)
        self._replace_window(PopupOverlay(self, content))

    def _show_prompt(self) -> None:
        """Present the global input box used by the Super+S shortcut."""
        self._replace_window(DictionaryPrompt(self, self._show_lookup))


def serve(database: Path = DEFAULT_DB) -> int:
    """Run the resident lookup service for the configured database."""
    return LookupService(database).run([])
