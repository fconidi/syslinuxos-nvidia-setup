# SysLinuxOS NVIDIA Setup

[Downloads](https://github.com/fconidi/syslinuxos-nvidia-setup/releases) · [Quick start](README.en.md) · [Changelog](CHANGELOG.md) · [Contributing](CONTRIBUTING.md)

A standalone Bash installer for **SysLinuxOS 13 and Debian 13 amd64**, with
a YAD graphical interface and a terminal alternative. The standalone script
is `syslinuxos-nvidia-setup.sh`.

## Version 1.1.1

Project documentation, the changelog and package build messages are in English.
The graphical interface, buttons, terminal help, messages and errors support
**English, Italian, Spanish, German and French**. The language is selected
automatically from the desktop session settings; **English is the default**
when the language is unsupported or unset. Application menu descriptions are
also localized.

Message locale selection follows the precedence `LC_ALL`, `LC_MESSAGES`,
`LANG`. For locales other than `C`/`POSIX`, the `LANGUAGE` preference list is
also respected, selecting the first supported language. Regional variants such
as `es_MX.UTF-8` and `fr_CA.UTF-8` select Spanish and French respectively.
`C`, `C.UTF-8` and `POSIX` select English.

The selected language is passed explicitly to the administrative worker, so
it remains consistent after sudo/pkexec authentication. Message catalogs are
embedded in the standalone script; no external translation files are needed.
Technical output from APT, DKMS and other commands remains in English to allow
consistent checks.

To test detection without installing drivers:

```bash
env LC_ALL= LC_MESSAGES= LANGUAGE= LANG=en_US.UTF-8 syslinuxos-nvidia-setup --help
env LC_ALL= LC_MESSAGES= LANGUAGE= LANG=C.UTF-8 syslinuxos-nvidia-setup --check --cli
```

## Repository key fix included since version 1.0.1

The exit code 22 / HTTP 404 failure while configuring the NVIDIA Debian 13
repository was corrected. The key is extracted from the official
`cuda-keyring_1.1-1_all.deb` package, validated as a GPG keyring and associated
with the repository through `Signed-By`.

## Install from the APT repository

The package is distributed through the signed
[SysLinuxOS-Tools repository](https://github.com/fconidi/SysLinuxOS-Tools#installation-client-side).
Configure the repository using the linked instructions, then run:

```bash
sudo apt update
sudo apt install --reinstall yad syslinuxos-nvidia-setup
syslinuxos-nvidia-setup --check --cli
```

The repository also supports **Debian 13 amd64**. Its `tirreno` suite identifies
this additional repository; the system's Debian repositories continue to use
`trixie`. To add only the signing key and APT source, use the manual setup
instructions in the SysLinuxOS-Tools repository.

## Install the Debian package

Download the `.deb` from [release v1.1.1](https://github.com/fconidi/syslinuxos-nvidia-setup/releases/tag/v1.1.1),
or build it with `build-deb.sh` (output is written to `dist/`):

```bash
sudo apt install --reinstall yad ./syslinuxos-nvidia-setup_1.1.1_amd64.deb
syslinuxos-nvidia-setup --check --cli
```

`yad` is a **required dependency** of the package (`Depends`): APT installs it
if it is missing. The recommended command names it explicitly with
`--reinstall`, so it is reinstalled even when already present. A GUI startup
failure with an existing YAD installation was resolved by reinstalling YAD.
Installing the `.deb` alone, without `--reinstall yad`, keeps an existing YAD
installation without restoring its files.

If the `.deb` is already installed, restore YAD alone with:

```bash
sudo apt reinstall yad
```

APT handles the reinstall through the recommended installation command.
Starting APT from a package `postinst` script would conflict with the locks
held by the APT/dpkg transaction already in progress.

Installing the package adds the utility, YAD and its prerequisites:
**it does not start driver installation**. In MATE, open
**Applications → SysLinuxOS-Tools → SysLinuxOS NVIDIA Setup**. If the entry
does not appear immediately, close and reopen the menu; if necessary, log out
and log back in.

The original MATE menu selects applications by their `.desktop` filename.
The package therefore adds a file under
`/etc/xdg/menus/applications-merged/`, using the existing internal menu name
`SysLinuxOS Tools`, without rewriting `mate-applications.menu`.
The dedicated SVG icon depicts a PCIe card with a fan and a green chip,
without text or official logos. It is installed in the `hicolor` theme and
scales to the menu icon size. The application entry is not duplicated in
MATE's System submenu.

When the window appears, choose **Driver only** or **Driver + CUDA**.
Administrative authentication follows; downloads, installation and DKMS
compilation then continue automatically. Closing the initial window cancels
the operation. Closing the log window during installation allows APT to finish:
keep the computer running until the operation completes.

Alternatively, extract the source archive and run the standalone script:

```bash
tar -xzf syslinuxos-nvidia-setup-1.1.1.tar.gz
cd syslinuxos-nvidia-setup-1.1.1
./syslinuxos-nvidia-setup.sh --check --cli
./syslinuxos-nvidia-setup.sh --gui
```

The portable version requires YAD and pkexec for the GUI
(`sudo apt install yad pkexec`). Launch the GUI as your normal user:
the privileged worker runs separately, including under Wayland.
For terminal use or automation:

```bash
./syslinuxos-nvidia-setup.sh --cli                 # asks whether to install CUDA
sudo ./syslinuxos-nvidia-setup.sh --cli --no-cuda  # no prompts
sudo ./syslinuxos-nvidia-setup.sh --cli --cuda     # includes CUDA
```

## Driver selection and compatibility

- Explicit support for SysLinuxOS 13 / Debian 13, amd64, installed on disk.
  The SysLinuxOS codename `tirreno` is not used as a Debian suite: the correct
  Debian suite is `trixie`.
- NVIDIA's official JSON database distinguishes modern GPUs compatible with
  the open NVIDIA kernel module from GPUs that require the proprietary module.
  Modern GPUs use NVIDIA's **Debian 13** repository, with `nvidia-open` and
  `nvidia-kernel-open-dkms`. Graphics user-space components remain proprietary;
  this is not the Nouveau driver.
- GPUs requiring the proprietary module use Debian's `nvidia-driver` and
  `nvidia-kernel-dkms` packages, with an additional `nvidia-detect` check.
  Legacy or ambiguous recommendations are not forced.
- CUDA uses NVIDIA's `cuda-toolkit` or Debian's `nvidia-cuda-toolkit`, matching
  the selected driver channel. The two channels are not mixed. For NVIDIA's
  toolkit, `/usr/local/cuda/bin` is added to the PATH of new sessions through
  `/etc/profile.d/syslinuxos-cuda.sh`.
- Unknown GPUs, legacy branches older than 580 and GPU combinations requiring
  incompatible modules are reported without forcing an installation.
- Headers must match the **running kernel** and be available through APT.
  The script does not install or select another kernel. Debian's 550 drivers
  are blocked on kernel 6.19 and newer, including SysLinuxOS kernel 7.0:
  affected GPUs require booting a compatible kernel before retrying.
  DKMS compilation checks other combinations.
- Debian's 550 branch is described by the Debian wiki as no longer maintained
  upstream; assess its suitability for the target machine.
- A previous NVIDIA `.run` installation requires its dedicated uninstall tool.
  If APT requires package removals to migrate an existing driver, the script
  stops and reports the reason rather than forcing the migration.

The installer downloads hardware data from
`raw.githubusercontent.com/NVIDIA/nvidia-driver-assistant`, NVIDIA packages
when needed from `developer.download.nvidia.com`, and Debian packages from
the configured repositories. APT keys are associated with individual
repositories through `Signed-By`; the JSON data is read, never executed.

## Secure Boot and verification after restarting

When Secure Boot is enabled, verification compares the module signing key
with the default DKMS certificate and checks whether it is enrolled.
If enrollment is missing, installation finishes with exit code **20** and
MOK instructions. With the standard DKMS configuration:

```bash
sudo mokutil --import /var/lib/dkms/mok.pub
```

Set a temporary password and restart. In the firmware screen, choose
`Enroll MOK → Continue → Yes` and enter the password.
If DKMS uses a custom signing key, enroll that key's certificate instead.
Firmware confirmation cannot be automated. The script does not disable
Secure Boot or restart the computer.

After restarting:

```bash
nvidia-smi
lsmod | grep nvidia
dkms status
nvcc --version   # only if CUDA was selected; open a new terminal
```

The `CUDA Version` field in `nvidia-smi` describes driver compatibility;
it does not prove that the toolkit is installed. `nvcc --version` checks
the compiler. Verifying actual GPU computation also requires running a CUDA
application on the NVIDIA machine.

## Logs, errors and removal

The administrative log is `/var/log/syslinuxos-nvidia-XXXXXXXX.log`.
The GUI also keeps a user-readable log at
`/tmp/syslinuxos-nvidia-session.XXXXXXXX.log`. APT, DKMS and initramfs errors
stop the operation; the log records the exit code and failure location.
Package installation can be partial: it is not a transaction with automatic
rollback.

Depending on the selected channel, the script adds
`/etc/apt/sources.list.d/syslinuxos-nvidia.sources` and
`/etc/apt/keyrings/syslinuxos-nvidia.gpg`, or
`/etc/apt/sources.list.d/syslinuxos-nvidia-nonfree.sources`.
Existing files that are modified are backed up with a `.bak.TIMESTAMP` suffix.
If Debian's non-free components were already enabled, APT may report duplicate
targets: the original sources are not rewritten. Repositories remain enabled
to receive driver updates.

To remove only the utility and its application menu entry:

```bash
sudo apt purge syslinuxos-nvidia-setup
```

Drivers, CUDA and APT configuration remain installed. If graphics problems
occur, use a working kernel from the GRUB menu or a text console, consult the
log and plan driver package removal through APT. Avoid indiscriminately
deleting NVIDIA libraries or initramfs files.

## Requirements and acceptance criteria

- Detect NVIDIA PCI display GPUs, including hybrid laptops; ignore NVIDIA
  HDMI audio and USB controllers. Make no changes when no GPU is detected.
- Request administrative privileges only for installation.
- Ask whether CUDA should be installed; also allow an explicit CLI choice.
- Select the module using NVIDIA hardware data. Use APT and signed repositories,
  check matching kernel headers and verify the DKMS result.
- Report unsupported hardware, incompatible kernels and Secure Boot requirements
  without claiming that a driver requiring a restart is already active.
- Do not restart automatically or stop the graphical session.
- Allow a local check without root, networking or changes.

## Development

```bash
git clone https://github.com/fconidi/syslinuxos-nvidia-setup.git
cd syslinuxos-nvidia-setup
```

The script uses Bash, `snake_case` functions and arrays for APT arguments,
without `eval`. Python 3 reads GPU JSON data only. Tests use `unittest` and
simulated system commands; they do not install packages.
The worker language is passed through the validated internal argument
`--ui-language=CODE`; initial language selection remains automatic.
Tests cover all supported languages, locale precedence, GUI buttons and
outcomes, message format arguments and language preservation across
administrative authentication.

On Debian 13 / SysLinuxOS 13, install the test and build prerequisites:

```bash
sudo apt install python3 dpkg-dev desktop-file-utils yad pkexec
```

Then validate and build:

```bash
bash -n syslinuxos-nvidia-setup.sh build-deb.sh
python3 -B -m unittest discover -s tests -v
python3 tests/check_mate_menu.py   # on SysLinuxOS MATE with gir1.2-matemenu-2.0
bash syslinuxos-nvidia-setup.sh --check --cli
desktop-file-validate syslinuxos-nvidia-setup.desktop
./build-deb.sh
cd dist
sha256sum --check SHA256SUMS
```

GitHub Actions checks Bash syntax, validates the desktop entry, runs tests
and builds the package on pushes and pull requests. The `.deb`, source
archive and `SHA256SUMS` are available in CI runs and releases.
Source archives exclude local `.git` metadata.

Keep changes limited to this installer and verify APT errors. Do not force
package removals, downgrades, held-package changes or kernel replacement.
Physical GPU installation and restart tests require a test machine with
NVIDIA hardware.

## Technical sources

- [GNU language preferences](https://www.gnu.org/software/gettext/manual/html_node/The-LANGUAGE-variable.html)
- [Desktop entry localization](https://specifications.freedesktop.org/desktop-entry/latest/localized-keys.html)
- [NVIDIA drivers on Debian](https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/debian.html)
- [NVIDIA kernel modules](https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/kernel-modules.html)
- [NVIDIA Driver Assistant database and logic](https://github.com/NVIDIA/nvidia-driver-assistant)
- [Debian driver/kernel compatibility](https://wiki.debian.org/NvidiaGraphicsDrivers)
- [Debian CUDA Toolkit](https://packages.debian.org/trixie/nvidia-cuda-toolkit)
- [CUDA and driver compatibility](https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/index.html)
