# Contributing

Open an issue or pull request at
<https://github.com/fconidi/syslinuxos-nvidia-setup>.

For a hardware or installation issue, include the operating system version,
`uname -r`, GPU model or PCI device ID, command used and relevant error output
from the installation log. State whether Secure Boot is enabled and whether
the driver was previously installed with APT or NVIDIA's `.run` installer.

Keep changes focused. Preserve all five message catalogs and their format
arguments. The script must remain standalone and support its read-only
`--check` mode without root or networking.

Before submitting:

```bash
bash -n syslinuxos-nvidia-setup.sh build-deb.sh
python3 -B -m unittest discover -s tests -v
desktop-file-validate syslinuxos-nvidia-setup.desktop
./build-deb.sh
cd dist
sha256sum --check SHA256SUMS
```

Physical GPU installation, restart and CUDA execution need separate hardware
tests. Describe these tests when a change affects driver installation.
