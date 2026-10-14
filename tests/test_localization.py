"""Language selection and translated flows, without installing drivers."""
import pathlib
import re
import tempfile
import unittest

from test_setup import SCRIPT, shell


def localized(code, *args, **locale):
    return shell(code, *args, env={
        "LC_ALL": "", "LC_MESSAGES": "", "LANG": "en_US.UTF-8", "LANGUAGE": "",
        **locale,
    })


class LocalizationTests(unittest.TestCase):
    def test_system_locales_select_all_five_languages(self):
        for language, locale in {
            "it": "it_IT.UTF-8", "en": "en_GB.UTF-8", "es": "es_MX.utf8",
            "de": "de_DE@euro", "fr": "fr_CA.UTF-8",
        }.items():
            with self.subTest(locale=locale):
                result = localized('detect_ui_language; printf "%s" "$UI_LANGUAGE"', LANG=locale)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout, language)

    def test_locale_category_precedence(self):
        for overrides, expected in [
            ({"LC_ALL": "de_DE.UTF-8", "LC_MESSAGES": "fr_FR.UTF-8", "LANG": "it_IT.UTF-8"}, "de"),
            ({"LC_MESSAGES": "es_ES.UTF-8", "LANG": "it_IT.UTF-8"}, "es"),
        ]:
            with self.subTest(overrides=overrides):
                result = localized('detect_ui_language; printf "%s" "$UI_LANGUAGE"', **overrides)
                self.assertEqual(result.stdout, expected)

    def test_language_priority_list_uses_first_supported_language(self):
        result = localized('detect_ui_language; printf "%s" "$UI_LANGUAGE"',
                           LANG="it_IT.UTF-8", LANGUAGE="pt_BR:fr_CA:de")
        self.assertEqual(result.stdout, "fr")

    def test_neutral_unknown_and_missing_locales_default_to_english(self):
        for locale in ("C", "C.UTF-8", "POSIX", "ja_JP.UTF-8", ""):
            with self.subTest(locale=locale):
                result = localized('detect_ui_language; printf "%s" "$UI_LANGUAGE"', LANG=locale)
                self.assertEqual(result.stdout, "en")
        result = localized('detect_ui_language; printf "%s" "$UI_LANGUAGE"',
                           LC_ALL="C", LANGUAGE="it:fr")
        self.assertEqual(result.stdout, "en")

    def test_help_and_no_gpu_check_are_translated(self):
        for language, heading, no_gpu in [
            ("en", "Usage:", "No NVIDIA GPU"), ("it", "Uso:", "Nessuna GPU NVIDIA"),
            ("es", "Uso:", "No se ha detectado"), ("de", "Aufruf:", "Keine NVIDIA-GPU"),
            ("fr", "Utilisation :", "Aucun GPU NVIDIA"),
        ]:
            with self.subTest(language=language):
                result = localized('main --help', LANG=language)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn(heading, result.stdout)
                result = localized('detect_gpus() { :; }; main --check --cli', LANG=language)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn(no_gpu, result.stdout)

    def test_worker_language_survives_reset_locale(self):
        result = localized('detect_gpus() { :; }; main --worker --check --cli --ui-language=fr',
                           LC_ALL="C")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Aucun GPU NVIDIA", result.stdout)

    def test_unsupported_explicit_language_is_rejected(self):
        result = localized('main --ui-language=../../invalid --check --cli')
        self.assertEqual(result.returncode, 1)
        self.assertIn("Unsupported language", result.stderr)

    def test_frontend_passes_language_through_privilege_boundary(self):
        with tempfile.TemporaryDirectory() as root:
            worker = pathlib.Path(root) / "worker.sh"
            worker.write_text('printf "%s\\n" "$@"\n')
            result = localized('sudo() { "$@"; }; '
                               'readlink() { printf "%s" "$TEST_WORKER"; }; '
                               'TEST_WORKER=$1; UI=cli; CUDA=no; UI_LANGUAGE=de; run_frontend',
                               str(worker), LC_ALL="C")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("--ui-language=de", result.stdout.splitlines())
        self.assertIn("--no-cuda", result.stdout.splitlines())

    def test_final_gui_dialogs_preserve_worker_outcome_and_language(self):
        with tempfile.TemporaryDirectory() as root:
            worker = pathlib.Path(root) / "worker.sh"
            worker.write_text('exit "$TEST_STATUS"\n')
            for language, complete, mok, incomplete, close in [
                ("en", "Installation complete.", "MOK key enrollment", "Installation incomplete", "Close"),
                ("it", "Installazione completata.", "registrazione della chiave MOK", "Installazione non completata", "Chiudi"),
                ("es", "Instalación completada.", "inscribir la clave MOK", "Instalación incompleta", "Cerrar"),
                ("de", "Installation abgeschlossen.", "Registrierung des MOK-Schlüssels", "Installation unvollständig", "Schließen"),
                ("fr", "Installation terminée.", "inscription de la clé MOK", "Installation incomplète", "Fermer"),
            ]:
                for status, message in [(0, complete), (20, mok), (42, incomplete)]:
                    with self.subTest(language=language, status=status):
                        result = localized('''
TEST_ROOT=$1; TEST_WORKER=$2; export TEST_STATUS=$3
UI_LANGUAGE=$4; UI=gui; CUDA=no
readlink() { printf '%s' "$TEST_WORKER"; }
sudo() { "$@"; }
pkexec() { "$@"; }
mktemp() { command mktemp "$TEST_ROOT/session.XXXXXXXX.log"; }
yad() {
    if [[ $* == *--text-info* ]]; then
        command cat >/dev/null
    else
        printf '%s\\n' "$@"
    fi
}
run_frontend
''', root, str(worker), str(status), language, LC_ALL="C")
                        self.assertEqual(result.returncode, status, result.stderr)
                        self.assertIn(message, result.stdout)
                        self.assertIn(f"--button={close}:0", result.stdout)

    def test_worker_error_keeps_code_line_and_log_in_all_languages(self):
        for language, prefix in {
            "en": "ERROR:", "it": "ERRORE:", "es": "ERROR:",
            "de": "FEHLER:", "fr": "ERREUR:",
        }.items():
            with self.subTest(language=language):
                result = localized('UI_LANGUAGE=$1; LOGFILE=/test/install.log; '
                                   'report_install_error 22 189', language, LC_ALL="C")
                self.assertEqual(result.returncode, 22)
                self.assertTrue(result.stderr.startswith(prefix))
                for value in ("22", "189", "/test/install.log"):
                    self.assertIn(value, result.stderr)
        result = localized('UI_LANGUAGE=fr; report_install_error 20 189', LC_ALL="C")
        self.assertEqual(result.returncode, 20)
        self.assertEqual(result.stderr, "")

    def test_gui_buttons_are_translated(self):
        for language, driver_button in {
            "en": "Driver only:2", "it": "Solo driver:2", "es": "Solo controlador:2",
            "de": "Nur Treiber:2", "fr": "Pilote seul:2",
        }.items():
            with self.subTest(language=language):
                result = localized('UI_LANGUAGE=$1; UI=gui; CUDA=ask; show_hardware() { :; }; '
                                   'yad() { printf "%s\\n" "$@"; return 2; }; ask_cuda', language)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn("--button=" + driver_button, result.stdout)

    def test_cli_accepts_localized_yes_answers(self):
        for language, answer in [("en", "yes"), ("it", "sì"), ("es", "sí"), ("de", "ja"), ("fr", "oui")]:
            with self.subTest(language=language):
                result = localized('UI_LANGUAGE=$1; UI=cli; CUDA=ask; ask_cuda <<< "$2"; '
                                   'printf "%s" "$CUDA"', language, answer)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout, "yes")

    def test_catalogs_are_complete_and_preserve_format_arguments(self):
        result = localized('for key in "${!MESSAGES[@]}"; do '
                           'printf "%s\\0%s\\0" "$key" "${MESSAGES[$key]}"; done')
        self.assertEqual(result.returncode, 0, result.stderr)
        values = result.stdout.split("\0")[:-1]
        catalogs = {language: {} for language in ("en", "it", "es", "de", "fr")}
        for key, text in zip(values[::2], values[1::2]):
            language, message = key.split(".", 1)
            catalogs[language][message] = text
        self.assertGreater(len(catalogs["en"]), 40)
        for language, catalog in catalogs.items():
            self.assertEqual(catalog.keys(), catalogs["en"].keys(), language)
            for key, text in catalog.items():
                self.assertTrue(text, (language, key))
                self.assertEqual(re.findall(r"%[sd]", text),
                                 re.findall(r"%[sd]", catalogs["en"][key]), (language, key))

    def test_python_gpu_errors_are_translated(self):
        with tempfile.TemporaryDirectory() as root:
            database = pathlib.Path(root) / "gpus.json"
            database.write_text('{"chips": []}')
            for language, text in [("en", "not in the NVIDIA database"), ("fr", "absent de la base NVIDIA")]:
                with self.subTest(language=language):
                    result = localized('UI_LANGUAGE=$2; classify_gpus "$1" 0xffff', str(database), language)
                    self.assertNotEqual(result.returncode, 0)
                    self.assertIn(text, result.stderr)

    def test_desktop_description_has_all_supported_translations(self):
        desktop = (SCRIPT.parent / "syslinuxos-nvidia-setup.desktop").read_text()
        self.assertIn("Comment=Install NVIDIA", desktop)
        for language in ("it", "es", "de", "fr"):
            self.assertIn(f"Comment[{language}]=", desktop)
