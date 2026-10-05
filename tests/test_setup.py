"""Tests run sourced functions with fake hardware; never install packages."""
import json
import os
import pathlib
import subprocess
import tempfile
import unittest

SCRIPT = pathlib.Path(__file__).resolve().parents[1] / "syslinuxos-nvidia-setup.sh"


def shell(code, *args, env=None):
    return subprocess.run(
        ["bash", "-c", 'source "$1"; shift; ' + code, "test", str(SCRIPT), *args],
        text=True, capture_output=True, env={**os.environ, **(env or {})},
    )


class DetectionTests(unittest.TestCase):
    def test_no_gpu_is_a_successful_empty_result(self):
        with tempfile.TemporaryDirectory() as root:
            result = shell('detect_gpus "$1"', root)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "")

    def test_display_only_including_3d_and_hybrid(self):
        with tempfile.TemporaryDirectory() as root:
            for address, vendor, cls in [
                ("0000:01:00.0", "0x10de", "0x030000"),
                ("0000:01:00.1", "0x10de", "0x040300"),
                ("0000:02:00.0", "0x10de", "0x030200"),
                ("0000:00:02.0", "0x8086", "0x030000"),
            ]:
                dev = pathlib.Path(root) / address
                dev.mkdir()
                for name, value in {"vendor": vendor, "class": cls, "device": "0x2684"}.items():
                    (dev / name).write_text(value + "\n")
            result = shell('detect_gpus "$1"', root)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.splitlines(), ["0000:01:00.0 0x2684", "0000:02:00.0 0x2684"])


class GpuSupportTests(unittest.TestCase):
    def classify(self, chips, devices):
        with tempfile.TemporaryDirectory() as root:
            path = pathlib.Path(root) / "gpus.json"
            path.write_text(json.dumps({"chips": chips}))
            return shell('classify_gpus "$1" "${@:2}"', str(path), *devices)

    def test_modern_gpu_uses_vendor_open_kernel(self):
        result = self.classify([{"devid": "0x2684", "features": ["kernelopen"]}], ["0x2684"])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "open")

    def test_maxwell_requires_closed_kernel(self):
        result = self.classify([{"devid": "0x13c2", "features": [], "legacybranch": "580.xx"}], ["0x13c2"])
        self.assertEqual(result.stdout.strip(), "closed")

    def test_unsupported_legacy_gpu_fails(self):
        result = self.classify([{"devid": "0x1180", "features": [], "legacybranch": "470.xx"}], ["0x1180"])
        self.assertNotEqual(result.returncode, 0)

    def test_unknown_gpu_does_not_guess(self):
        self.assertNotEqual(self.classify([], ["0xffff"]).returncode, 0)

    def test_mixed_old_and_open_required_gpus_fail(self):
        result = self.classify([
            {"devid": "0x13c2", "features": []},
            {"devid": "0x2b85", "features": ["kernelopen"]},
        ], ["0x13c2", "0x2b85"])
        self.assertNotEqual(result.returncode, 0)

    def test_mixed_old_and_dual_supported_gpus_use_closed(self):
        result = self.classify([
            {"devid": "0x13c2", "features": []},
            {"devid": "0x2684", "features": ["kernelopen", "gsp_proprietary_supported"]},
        ], ["0x13c2", "0x2684"])
        self.assertEqual(result.stdout.strip(), "closed")


class PolicyTests(unittest.TestCase):
    def test_syslinuxos_codename_is_not_used_as_debian_suite(self):
        with tempfile.TemporaryDirectory() as root:
            path = pathlib.Path(root) / "os-release"
            path.write_text('ID=SysLinuxOS\nVERSION_ID="13"\nVERSION_CODENAME=tirreno\n')
            result = shell('check_platform "$1" amd64; printf "%s" "$SUITE"', str(path))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "trixie")

    def test_ubuntu_is_rejected(self):
        with tempfile.TemporaryDirectory() as root:
            path = pathlib.Path(root) / "os-release"
            path.write_text('ID=ubuntu\nVERSION_ID="24.04"\n')
            result = shell('check_platform "$1" amd64', str(path))
        self.assertNotEqual(result.returncode, 0)

    def test_missing_candidate_is_rejected(self):
        result = shell('apt-cache() { printf "  Candidate: (none)\\n"; }; candidate nvidia-driver')
        self.assertNotEqual(result.returncode, 0)

    def test_550_with_new_kernel_is_rejected(self):
        result = shell('check_kernel_compatibility 550.163.01-4 7.0.7+deb13-amd64')
        self.assertNotEqual(result.returncode, 0)

    def test_550_with_standard_trixie_kernel_is_allowed(self):
        result = shell('check_kernel_compatibility 550.163.01-4 6.12.73+deb13-amd64')
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_apt_error_is_propagated(self):
        result = shell('apt-get() { return 42; }; apt_install nvidia-driver')
        self.assertEqual(result.returncode, 42)

    def test_apt_forbids_removals_and_is_noninteractive(self):
        result = shell('apt-get() { printf "%s\\n" "$DEBIAN_FRONTEND" "$@"; }; apt_install nvidia-driver')
        self.assertIn("noninteractive", result.stdout)
        self.assertIn("--no-remove", result.stdout)
        self.assertIn("nvidia-driver", result.stdout)

    def test_driver_recommendation_must_be_exact(self):
        result = shell("printf 'Recommended package:\\n    nvidia-driver\\n' | parse_recommendation")
        self.assertEqual(result.stdout.strip(), "nvidia-driver")
        result = shell("printf 'unsupported; try nvidia-driver perhaps\\n' | parse_recommendation")
        self.assertNotEqual(result.returncode, 0)


class RepositoryTests(unittest.TestCase):
    def configure_repository(self, download_error=0, corrupt_package=False):
        with tempfile.TemporaryDirectory() as root:
            root = pathlib.Path(root)
            workdir = root / "work"
            workdir.mkdir()
            keyring = b"NVIDIA test keyring\n"
            (root / "keyring.gpg").write_bytes(keyring)
            staging = root / "package"
            (staging / "DEBIAN").mkdir(parents=True)
            (staging / "DEBIAN/control").write_text(
                "Package: cuda-keyring\nVersion: 1.1-1\nArchitecture: all\n"
                "Maintainer: Test <test@example.com>\nDescription: Test keyring\n"
            )
            key = staging / "usr/share/keyrings/cuda-archive-keyring.gpg"
            key.parent.mkdir(parents=True)
            key.write_bytes(keyring)
            package = root / "cuda-keyring.deb"
            subprocess.run(
                ["dpkg-deb", "--root-owner-group", "--build", str(staging), str(package)],
                check=True, capture_output=True,
            )
            if corrupt_package:
                package.write_bytes(b"invalid Debian archive\n")
            result = shell('''
set -Eeuo pipefail
TEST_ROOT=$1
WORKDIR=$2
DOWNLOAD_ERROR=$3
curl() {
    local url= output=
    while (($#)); do
        case "$1" in
            -o) output=$2; shift 2 ;;
            https://*) url=$1; shift ;;
            *) shift ;;
        esac
    done
    if [[ $DOWNLOAD_ERROR != 0 ]]; then return "$DOWNLOAD_ERROR"; fi
    case "$url" in
        https://developer.download.nvidia.com/compute/cuda/repos/debian13/x86_64/cuda-keyring_*.deb)
            cp "$TEST_ROOT/cuda-keyring.deb" "$output" ;;
        *) printf 'curl: (22) The requested URL returned error: 404\\n' >&2; return 22 ;;
    esac
}
gpg() { cmp -s "$TEST_ROOT/keyring.gpg" "${@: -1}"; }
install() { [[ $* == '-d -m 0755 /etc/apt/keyrings' ]]; }
install_config() { cp "$1" "$TEST_ROOT/${2##*/}"; }
apt_update() { touch "$TEST_ROOT/apt-updated"; }
enable_nvidia_repository
''', str(root), str(workdir), str(download_error))
            installed = {}
            for name in ("syslinuxos-nvidia.gpg", "syslinuxos-nvidia.sources", "apt-updated"):
                path = root / name
                if path.exists():
                    installed[name] = path.read_bytes()
        return result, installed

    def test_repository_key_is_extracted_from_available_nvidia_package(self):
        result, installed = self.configure_repository()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(installed["syslinuxos-nvidia.gpg"], b"NVIDIA test keyring\n")
        self.assertIn(b"Signed-By: /etc/apt/keyrings/syslinuxos-nvidia.gpg",
                      installed["syslinuxos-nvidia.sources"])
        self.assertIn("apt-updated", installed)

    def test_keyring_download_failure_does_not_configure_repository(self):
        result, installed = self.configure_repository(download_error=22)
        self.assertEqual(result.returncode, 22)
        self.assertEqual(installed, {})

    def test_invalid_keyring_package_does_not_configure_repository(self):
        result, installed = self.configure_repository(corrupt_package=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(installed, {})

    def test_cleanup_removes_downloaded_keyring_package(self):
        with tempfile.TemporaryDirectory() as root:
            workdir = pathlib.Path(root) / "work"
            workdir.mkdir()
            (workdir / "cuda-keyring.deb").touch()
            result = shell('WORKDIR=$1; worker_cleanup', str(workdir))
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertFalse(workdir.exists())


class InterfaceTests(unittest.TestCase):
    def test_help_does_not_require_root(self):
        result = subprocess.run(["bash", str(SCRIPT), "--help"], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0)
        self.assertIn("--check", result.stdout)

    def test_invalid_flag_fails(self):
        result = subprocess.run(["bash", str(SCRIPT), "--not-an-option"], capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)

    def test_declining_cuda_does_not_cancel_driver(self):
        result = shell('UI=cli; CUDA=ask; ask_cuda <<< n; printf "%s" "$CUDA"')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(result.stdout.endswith("no"))

    def test_unattended_requires_explicit_cuda_choice(self):
        result = shell('UI=cli; CUDA=ask; ask_cuda </dev/null')
        self.assertNotEqual(result.returncode, 0)

    def test_gui_driver_only_choice(self):
        result = shell('UI=gui; CUDA=ask; show_hardware() { :; }; yad() { return 2; }; '
                       'ask_cuda; printf "%s" "$CUDA"')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "no")

    def test_gui_cuda_choice(self):
        result = shell('UI=gui; CUDA=ask; show_hardware() { :; }; yad() { return 0; }; '
                       'ask_cuda; printf "%s" "$CUDA"')
        self.assertEqual(result.stdout, "yes")

    def test_gui_close_cancels_installation(self):
        result = shell('UI=gui; CUDA=ask; show_hardware() { :; }; yad() { return 252; }; ask_cuda')
        self.assertEqual(result.returncode, 2)

    def test_gui_display_failure_is_an_error(self):
        result = shell('UI=gui; CUDA=ask; show_hardware() { :; }; yad() { return 125; }; ask_cuda')
        self.assertEqual(result.returncode, 1)

    def test_no_gpu_never_prompts_or_requests_privileges(self):
        result = shell('set -Eeuo pipefail; detect_gpus() { :; }; '
                       'ask_cuda() { exit 98; }; run_frontend() { exit 99; }; main --cli',
                       env={"LC_ALL": "C"})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("No NVIDIA GPU", result.stdout)

    def test_check_with_gpu_never_installs(self):
        result = shell('set -Eeuo pipefail; detect_gpus() { printf "0000:01:00.0 0x2684\\n"; }; '
                       'ask_cuda() { exit 98; }; run_frontend() { exit 99; }; main --cli --check')
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_check_also_overrides_internal_worker_mode(self):
        result = shell('set -Eeuo pipefail; detect_gpus() { printf "0000:01:00.0 0x2684\\n"; }; '
                       'install_stack() { exit 99; }; main --worker --check --no-cuda')
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_cancel_stops_before_privilege_request(self):
        result = shell('set -Eeuo pipefail; detect_gpus() { printf "0000:01:00.0 0x2684\\n"; }; '
                       'check_platform() { :; }; show_hardware() { :; }; '
                       'ask_cuda() { return 2; }; run_frontend() { exit 99; }; main --gui')
        self.assertEqual(result.returncode, 2)


class VerificationTests(unittest.TestCase):
    def test_dkms_failure_stops_before_initramfs(self):
        result = shell('set -Eeuo pipefail; dkms() { return 43; }; '
                       'update-initramfs() { exit 99; }; verify_module 7.0.7 615.71.09-2')
        self.assertEqual(result.returncode, 43)

    def test_stale_module_is_not_reported_as_success(self):
        result = shell('set -Eeuo pipefail; dkms() { :; }; depmod() { :; }; '
                       'modinfo() { printf "550.163.01\\n"; }; '
                       'update-initramfs() { exit 99; }; verify_module 7.0.7 615.71.09-2')
        self.assertEqual(result.returncode, 1)
        self.assertIn("differs from package", result.stderr)

    def test_matching_module_updates_initramfs(self):
        result = shell('set -Eeuo pipefail; dkms() { :; }; depmod() { :; }; '
                       'modinfo() { printf "615.71.09\\n"; }; '
                       'update-initramfs() { printf "INITRAMFS %s\\n" "$*"; }; '
                       'verify_module 7.0.7 3:615.71.09-2')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("INITRAMFS -u -k 7.0.7", result.stdout)

    def test_enrolled_certificate_must_match_module_signature(self):
        with tempfile.NamedTemporaryFile() as cert:
            result = shell('modinfo() { printf "AA:BB\\n"; }; '
                           'openssl() { printf "X509v3 Subject Key Identifier:\\n CC:DD\\n"; }; '
                           'mokutil() { return 0; }; module_key_enrolled 7.0.7 "$1"', cert.name)
        self.assertNotEqual(result.returncode, 0)

    def test_matching_enrolled_certificate_is_accepted(self):
        with tempfile.NamedTemporaryFile() as cert:
            result = shell('modinfo() { printf "aa:bb\\n"; }; '
                           'openssl() { printf "X509v3 Subject Key Identifier:\\n AA:BB\\n"; }; '
                           'mokutil() { return 0; }; module_key_enrolled 7.0.7 "$1"', cert.name)
        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
