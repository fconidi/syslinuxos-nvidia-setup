# Changelog

## 1.1.1

- Translate the complete project documentation and changelog into English.
- Use English package build messages and include the updated guides in the
  Debian package and source archive.
- Document the development prerequisites used by CI, including YAD.

## 1.1.0

- Graphical interface, help and messages in English, Italian, Spanish, German
  and French, with automatic language selection.
- English default for unsupported locales and consistent language after
  administrative authentication.
- Localized application menu descriptions; YAD required by the Debian package.
- Installation procedure that restores YAD even when it is already installed.
- GitHub distribution and the signed SysLinuxOS-Tools APT repository, supporting
  SysLinuxOS 13 and Debian 13 amd64.

## 1.0.1

- Correct NVIDIA Debian 13 repository configuration: extract the GPG key from
  the official `cuda-keyring` package to avoid the HTTP 404 failure.

## 1.0.0

- NVIDIA GPU detection and selection of a compatible kernel module.
- Driver installation through APT, optional CUDA and DKMS verification.
- YAD interface, terminal mode and MATE menu integration.
- Kernel compatibility checks and Secure Boot/MOK instructions.
