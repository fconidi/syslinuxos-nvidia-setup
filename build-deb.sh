#!/usr/bin/env bash
set -Eeuo pipefail
cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"
version=$(awk '$1 == "Version:" {print $2}' packaging/control)
staging=$(mktemp -d /tmp/syslinuxos-nvidia-deb.XXXXXXXX)
# Only this private, freshly created staging directory is removed.
trap 'rm -rf -- "$staging"' EXIT
chmod 0755 "$staging"
install -Dm0644 packaging/control "$staging/DEBIAN/control"
install -Dm0755 syslinuxos-nvidia-setup.sh "$staging/usr/bin/syslinuxos-nvidia-setup"
install -Dm0644 syslinuxos-nvidia-setup.desktop "$staging/usr/share/applications/syslinuxos-nvidia-setup.desktop"
install -Dm0644 icons/syslinuxos-nvidia-setup.svg "$staging/usr/share/icons/hicolor/scalable/apps/syslinuxos-nvidia-setup.svg"
install -Dm0644 syslinuxos-nvidia-setup.menu "$staging/etc/xdg/menus/applications-merged/syslinuxos-nvidia-setup.menu"
install -Dm0644 README.md "$staging/usr/share/doc/syslinuxos-nvidia-setup/README.md"
install -Dm0644 README.en.md "$staging/usr/share/doc/syslinuxos-nvidia-setup/README.en.md"
install -Dm0644 CHANGELOG.md "$staging/usr/share/doc/syslinuxos-nvidia-setup/CHANGELOG.md"
printf '%s\n' /etc/xdg/menus/applications-merged/syslinuxos-nvidia-setup.menu > "$staging/DEBIAN/conffiles"
mkdir -p dist
dpkg-deb --root-owner-group --build "$staging" "dist/syslinuxos-nvidia-setup_${version}_amd64.deb"
tar --exclude=./.git --exclude=dist --exclude=__pycache__ --exclude='*.pyc' \
    --transform="s,^\.,syslinuxos-nvidia-setup-${version}," \
    -czf "dist/syslinuxos-nvidia-setup-${version}.tar.gz" .
(
    cd dist
    sha256sum "syslinuxos-nvidia-setup_${version}_amd64.deb" \
        "syslinuxos-nvidia-setup-${version}.tar.gz" > SHA256SUMS
)
printf 'Creati pacchetto Debian, archivio sorgenti e checksum in %s/dist\n' "$PWD"
