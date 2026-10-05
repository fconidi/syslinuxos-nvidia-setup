# SysLinuxOS NVIDIA Setup: quick start

[Complete documentation](README.md) · [Downloads](https://github.com/fconidi/syslinuxos-nvidia-setup/releases)

A standalone Bash installer for **SysLinuxOS 13 and Debian 13 amd64**.
It detects NVIDIA display adapters, installs compatible drivers through APT,
and optionally installs CUDA Toolkit. The YAD interface and terminal messages
support English, Italian, Spanish, German and French. Language selection is
automatic, with English as the default.

## Install from APT

Configure the signed [SysLinuxOS-Tools repository](https://github.com/fconidi/SysLinuxOS-Tools#installation-client-side),
then run:

```bash
sudo apt update
sudo apt install --reinstall yad syslinuxos-nvidia-setup
syslinuxos-nvidia-setup --check --cli
```

The additional repository uses the suite `tirreno` on both supported systems;
Debian's own repositories continue to use `trixie`. The repository's manual
setup instructions add the signing key and APT source.

## Install the Debian package

Download the `.deb` from [release v1.1.1](https://github.com/fconidi/syslinuxos-nvidia-setup/releases/tag/v1.1.1):

```bash
sudo apt install --reinstall yad ./syslinuxos-nvidia-setup_1.1.1_amd64.deb
```

YAD is a required dependency. Explicitly reinstalling it restores its files
even when it is already installed; this resolved a reported GUI startup failure.
For an existing installation, use `sudo apt reinstall yad` to restore YAD alone.
Installing the utility does not install GPU drivers automatically.

Launch **SysLinuxOS NVIDIA Setup** from your application menu, or run:

```bash
syslinuxos-nvidia-setup --gui
```

Choose **Driver only** or **Driver + CUDA**, then authenticate. Launch the GUI
as your normal desktop user. Installation runs in a separate privileged worker.
Closing the log window allows APT to finish; the computer is not restarted.

## Terminal and portable use

The source archive contains the standalone script. YAD and pkexec are needed
for its GUI (`sudo apt install yad pkexec`). Terminal examples:

```bash
./syslinuxos-nvidia-setup.sh --check --cli
./syslinuxos-nvidia-setup.sh --cli
sudo ./syslinuxos-nvidia-setup.sh --cli --no-cuda
sudo ./syslinuxos-nvidia-setup.sh --cli --cuda
```

`--check` reads local hardware information without root, networking or changes.

## Compatibility and verification

- Drivers are selected using NVIDIA's hardware data and signed APT repositories.
  Open kernel modules are used where supported; older supported GPUs use
  Debian's proprietary driver stack.
- Headers must match the running kernel. The installer does not replace the
  kernel. Debian's 550 driver is rejected on kernel 6.19 and newer.
- Unknown GPUs, unsupported legacy branches and incompatible GPU combinations
  require manual configuration. Previous NVIDIA `.run` installations must be
  removed with their own uninstall tool before using APT.
- Secure Boot may require manual MOK enrollment. Exit code 20 means packages
  were installed and enrollment is still required; follow the log instructions.

After restarting, check `nvidia-smi` and `dkms status`. If CUDA was selected,
check `nvcc --version` in a new terminal. Administrative logs are stored in
`/var/log/syslinuxos-nvidia-XXXXXXXX.log`; GUI session logs are in
`/tmp/syslinuxos-nvidia-session.XXXXXXXX.log`.

See the [complete guide](README.md) for repository details, Secure Boot enrollment,
driver selection, removal instructions and technical sources.

## Build and test

```bash
git clone https://github.com/fconidi/syslinuxos-nvidia-setup.git
cd syslinuxos-nvidia-setup
sudo apt install python3 dpkg-dev desktop-file-utils yad pkexec
bash -n syslinuxos-nvidia-setup.sh build-deb.sh
python3 -B -m unittest discover -s tests -v
desktop-file-validate syslinuxos-nvidia-setup.desktop
./build-deb.sh
cd dist
sha256sum --check SHA256SUMS
```

Build output includes the `.deb`, source archive and checksums. GitHub Actions
runs validation, tests and builds for pushes and pull requests. Tests simulate
hardware and privileged commands; they do not install drivers.
