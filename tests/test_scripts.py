"""Offline tests in temporary files; never touch the host's live PAM stack."""
import importlib.util
import os
from pathlib import Path
import stat
from unittest import mock
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("edit_gdm", ROOT / "scripts/lib/edit-gdm.py")
editor = importlib.util.module_from_spec(spec)
spec.loader.exec_module(editor)

EXAMPLE = b'#%PAM-1.0\nauth requisite pam_nologin.so\nauth\trequired\tpam_usb.so\n@include common-auth\nauth optional pam_gnome_keyring.so\n'


class GdmRecoveryTests(unittest.TestCase):
    def test_preserves_other_lines_and_permissions(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'gdm-password'
            path.write_bytes(EXAMPLE)
            path.chmod(0o640)
            self.assertEqual(editor.process(path), 0)
            self.assertEqual(path.read_bytes(), EXAMPLE.replace(b'auth\trequired\tpam_usb.so', b'# auth\trequired\tpam_usb.so'))
            self.assertEqual(stat.S_IMODE(path.stat().st_mode), 0o640)
            self.assertEqual(list(Path(tmp).glob('.gdm-password-usb-*')), [])
            after = path.read_bytes()
            self.assertEqual(editor.process(path), 3)
            self.assertEqual(path.read_bytes(), after)

    def test_read_only_check(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'gdm-password'
            path.write_bytes(EXAMPLE)
            inode = path.stat().st_ino
            self.assertEqual(editor.process(path, check=True), 0)
            self.assertEqual(path.read_bytes(), EXAMPLE)
            self.assertEqual(path.stat().st_ino, inode)

    def test_refuses_duplicate_other_and_missing_rules(self):
        cases = [
            EXAMPLE + b'auth required pam_usb.so\n',
            EXAMPLE.replace(b'required\tpam_usb.so', b'sufficient\tpam_usb.so'),
            b'@include common-auth\n',
        ]
        for data in cases:
            with self.subTest(data=data), tempfile.TemporaryDirectory() as tmp:
                path = Path(tmp) / 'gdm-password'
                path.write_bytes(data)
                with self.assertRaises(ValueError):
                    editor.process(path)
                self.assertEqual(path.read_bytes(), data)

    def test_refuses_symlink(self):
        with tempfile.TemporaryDirectory() as tmp:
            actual = Path(tmp) / 'actual'
            actual.write_bytes(EXAMPLE)
            symlink = Path(tmp) / 'symlink'
            symlink.symlink_to(actual)
            with self.assertRaises(ValueError):
                editor.process(symlink)
            self.assertEqual(actual.read_bytes(), EXAMPLE)

    def test_preserves_crlf_and_no_trailing_newline(self):
        for data in (EXAMPLE.replace(b'\n', b'\r\n'), b'auth required pam_usb.so'):
            with self.subTest(data=data):
                expected = data.replace(b'auth', b'# auth', 1) if data.startswith(b'auth') else data.replace(b'auth\trequired\tpam_usb.so', b'# auth\trequired\tpam_usb.so')
                self.assertEqual(editor.prepare(data), expected)

    def test_preserves_rule_options(self):
        self.assertEqual(editor.prepare(b'  auth required pam_usb.so debug\n'), b'#   auth required pam_usb.so debug\n')

    def test_preserves_extended_file_attributes(self):
        if not all(hasattr(os, name) for name in ("setxattr", "getxattr", "listxattr")):
            self.skipTest("Extended attributes are unsupported on this platform")
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'gdm-password'
            path.write_bytes(EXAMPLE)
            path.chmod(0o640)
            attribute = 'user.usb_token_test'
            try:
                os.setxattr(path, attribute, b'preserve-this')
            except OSError as exc:
                self.skipTest(f"Extended attributes unavailable on test filesystem: {exc}")
            self.assertEqual(editor.process(path), 0)
            self.assertEqual(os.getxattr(path, attribute), b'preserve-this')
            self.assertEqual(stat.S_IMODE(path.stat().st_mode), 0o640)
            self.assertEqual(list(Path(tmp).glob('.gdm-password-usb-*')), [])

    def test_failed_attribute_copy_does_not_modify_original(self):
        if not all(hasattr(os, name) for name in ("setxattr", "getxattr", "listxattr")):
            self.skipTest("Extended attributes are unsupported on this platform")
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'gdm-password'
            path.write_bytes(EXAMPLE)
            attribute = 'user.usb_token_test'
            try:
                os.setxattr(path, attribute, b'keep-original')
            except OSError as exc:
                self.skipTest(f"Extended attributes unavailable on test filesystem: {exc}")
            original_inode = path.stat().st_ino
            with mock.patch.object(editor.os, 'setxattr', side_effect=PermissionError("Simulated xattr failure")):
                with self.assertRaises(PermissionError):
                    editor.process(path)
            self.assertEqual(path.stat().st_ino, original_inode)
            self.assertEqual(path.read_bytes(), EXAMPLE)
            self.assertEqual(os.getxattr(path, attribute), b'keep-original')
            self.assertEqual(list(Path(tmp).glob('.gdm-password-usb-*')), [])


class ShellTests(unittest.TestCase):
    def test_syntax_and_help(self):
        for script in sorted((ROOT / 'scripts').rglob('*.sh')):
            with self.subTest(script=script.name):
                subprocess.run(['bash', '-n', str(script)], check=True, capture_output=True)
                if script.parent == ROOT / 'scripts':
                    result = subprocess.run(['bash', str(script), '--help'], check=True, capture_output=True, text=True)
                    self.assertIn('Usage:', result.stdout)

    def test_recovery_refuses_noninteractive_input(self):
        result = subprocess.run(
            ['bash', str(ROOT / 'scripts/recover-access.sh')],
            input='CONFIRM\n', capture_output=True, text=True
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue('interactive terminal' in result.stderr or 'sudo' in result.stderr)

    def test_rejects_unknown_arguments(self):
        for script in (ROOT / 'scripts').glob('*.sh'):
            result = subprocess.run(
                ['bash', str(script), '--unknown-argument', 'extra'],
                capture_output=True, text=True
            )
            self.assertNotEqual(result.returncode, 0)


class DocumentationStructureTests(unittest.TestCase):
    """Prevent method guide mix-ups during subsequent editorial changes."""

    def test_guides_match_expected_topics(self):
        headings = {
            'DISABLE_USB_TOKEN.md': '# Temporarily disable USB authentication',
            'scripts/README.md': '# Interactive project tools',
            'method-01/README.md': '# Method 01 — USB-based',
            'method-02/part-01.md': '# Method 02 — Part 01:',
            'method-02/part-02.md': '# Method 02 — Part 02:',
        }
        for name, heading in headings.items():
            with self.subTest(path=name):
                first_line = (ROOT / name).read_text(encoding='utf-8').splitlines()[0]
                self.assertTrue(first_line.startswith(heading), (name, first_line))


if __name__ == '__main__':
    unittest.main()
