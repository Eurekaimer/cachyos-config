from __future__ import annotations

import unittest
import tempfile
from pathlib import Path
from unittest import mock

from sioyek_ecdict.dictionary import Entry
from sioyek_ecdict.cli import main
from sioyek_ecdict.integration import _service_unit
from sioyek_ecdict.presentation import present_entry


class IntegrationTest(unittest.TestCase):

    def test_service_preloads_layer_shell(self) -> None:
        """The user service loads layer-shell before GTK's Wayland client."""
        unit = _service_unit(
            Path("/tmp/sioyek-ecdict"), Path("/tmp/ecdict.sqlite3")
        )
        self.assertIn("LD_PRELOAD=libgtk4-layer-shell.so.0", unit)
        self.assertIn(
            'ExecStart="/tmp/sioyek-ecdict" --database "/tmp/ecdict.sqlite3" serve',
            unit,
        )
        self.assertIn("PartOf=graphical-session.target", unit)
        self.assertIn("WantedBy=graphical-session.target", unit)
        self.assertNotIn("WantedBy=default.target", unit)

    def test_empty_selection_is_a_silent_noop(self) -> None:
        """Pressing the shortcut without selected text never opens a popup."""
        self.assertEqual(main(["lookup", "--popup"]), 0)

    def test_bootstrap_imports_a_missing_database_then_configures(self) -> None:
        """A fresh bootstrap creates ECDICT before wiring Sioyek to that path."""
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            database = root / "ecdict.sqlite3"
            configured = (root / "prefs", root / "keys", root / "unit", "s")
            with (
                mock.patch(
                    "sioyek_ecdict.cli.import_ecdict", return_value=(10, 3)
                ) as importer,
                mock.patch(
                    "sioyek_ecdict.cli.configure_sioyek",
                    return_value=configured,
                ) as configure,
            ):
                result = main(
                    [
                        "--database",
                        str(database),
                        "bootstrap",
                        "fixture.csv",
                    ]
                )
        self.assertEqual(result, 0)
        importer.assert_called_once_with("fixture.csv", database)
        configure.assert_called_once_with(database=database)

    def test_bootstrap_reuses_an_existing_database(self) -> None:
        """Repeated bootstrap skips the large import and refreshes integration."""
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            database = root / "ecdict.sqlite3"
            database.touch()
            configured = (root / "prefs", root / "keys", root / "unit", "s")
            with (
                mock.patch("sioyek_ecdict.cli.import_ecdict") as importer,
                mock.patch(
                    "sioyek_ecdict.cli.configure_sioyek",
                    return_value=configured,
                ) as configure,
            ):
                result = main(["--database", str(database), "bootstrap"])
        self.assertEqual(result, 0)
        importer.assert_not_called()
        configure.assert_called_once_with(database=database)

    def test_configuration_is_idempotent(self) -> None:
        """Repeated installation keeps one space-delimited direct binding."""
        from sioyek_ecdict.integration import configure_sioyek

        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            environment = {
                "XDG_CONFIG_HOME": str(root / "config"),
                "XDG_DATA_HOME": str(root / "data"),
            }
            with mock.patch.dict("os.environ", environment):
                configure_sioyek(
                    root / "sioyek-ecdict",
                    database=root / "data/ecdict.sqlite3",
                    manage_service=False,
                )
                prefs, keys, unit, shortcut = configure_sioyek(
                    root / "sioyek-ecdict",
                    database=root / "data/ecdict.sqlite3",
                    manage_service=False,
                )
            self.assertEqual(shortcut, "s")
            self.assertEqual(prefs.read_text().count("new_command _ecdict"), 1)
            self.assertNotIn("search_url_", prefs.read_text())
            self.assertNotIn("external_search", keys.read_text())
            self.assertTrue(keys.read_text().rstrip().endswith("_ecdict s"))
            self.assertTrue(unit.exists())

    def test_configuration_reenables_service_after_unit_target_changes(self) -> None:
        """Reinstallation replaces stale systemd enablement symlinks."""
        from sioyek_ecdict.integration import configure_sioyek

        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            environment = {
                "XDG_CONFIG_HOME": str(root / "config"),
                "XDG_DATA_HOME": str(root / "data"),
            }
            with (
                mock.patch.dict("os.environ", environment),
                mock.patch("sioyek_ecdict.integration.subprocess.run") as run,
            ):
                configure_sioyek(
                    root / "sioyek-ecdict",
                    database=root / "data/ecdict.sqlite3",
                )

        self.assertEqual(
            run.call_args_list,
            [
                mock.call(["systemctl", "--user", "daemon-reload"], check=True),
                mock.call(
                    ["systemctl", "--user", "reenable", "sioyek-ecdict.service"],
                    check=True,
                ),
                mock.call(
                    ["systemctl", "--user", "restart", "sioyek-ecdict.service"],
                    check=True,
                ),
            ],
        )

    def test_presentation_exposes_lemma_and_frequency(self) -> None:
        """Presentation includes lemma and frequency context."""
        entry = Entry(
            word="study",
            phonetic="ˈstʌdi",
            translation="学习\\n研究",
            definition="",
            pos="v.",
            collins=4,
            oxford=True,
            tag="cet4",
            bnc=1000,
            frq=800,
            matched_form="studied",
        )
        result = present_entry("studied", entry, [])
        self.assertEqual(result.title, "study")
        self.assertIn("studied → study", result.metadata)
        self.assertIn("现代词频 #800", result.metadata)
        self.assertEqual(result.translation, "学习\n研究")


if __name__ == "__main__":
    unittest.main()
