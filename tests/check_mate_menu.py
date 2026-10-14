"""Resolve the actual MATE menu against staged files; no system installation."""
import pathlib
import shutil
import tempfile
import xml.etree.ElementTree as ET

import gi

gi.require_version("MateMenu", "2.0")
from gi.repository import MateMenu

source = pathlib.Path(__file__).resolve().parents[1]
desktop_id = "syslinuxos-nvidia-setup.desktop"

with tempfile.TemporaryDirectory(prefix="syslinuxos-menu-test-") as directory:
    root = pathlib.Path(directory)
    merged = root / "applications-merged"
    merged.mkdir()
    shutil.copy(source / "syslinuxos-nvidia-setup.menu", merged)
    apps = root / "apps"
    apps.mkdir()
    desktop_text = (source / desktop_id).read_text()
    # The binary has not been installed into /usr/bin on this machine.
    # GLib filters entries with missing executables, so resolve the staged one.
    desktop_text = desktop_text.replace(
        "Exec=/usr/bin/syslinuxos-nvidia-setup",
        f'Exec="{source / "syslinuxos-nvidia-setup.sh"}"',
    )
    (apps / desktop_id).write_text(desktop_text)

    # Reuse the installed MATE menu rules with our desktop entry in isolation.
    document = ET.parse("/etc/xdg/menus/mate-applications.menu")
    menu = document.getroot()
    for node in list(menu):
        if node.tag in {"DefaultAppDirs", "AppDir"}:
            menu.remove(node)
    ET.SubElement(menu, "AppDir").text = str(apps)
    path = root / "mate-applications.menu"
    document.write(path, encoding="utf-8", xml_declaration=True)
    tree = MateMenu.Tree.new_for_path(str(path), MateMenu.TreeFlags.NONE)
    tree.load_sync()
    matches = []

    def walk(directory, parents):
        current = parents + [directory.get_menu_id()]
        iterator = directory.iter()
        while True:
            item_type = iterator.next()
            if item_type == MateMenu.TreeItemType.INVALID:
                break
            if item_type == MateMenu.TreeItemType.DIRECTORY:
                walk(iterator.get_directory(), current)
            elif item_type == MateMenu.TreeItemType.ENTRY:
                entry = iterator.get_entry()
                if entry.get_desktop_file_id() == desktop_id:
                    matches.append(current)

    walk(tree.get_root_directory(), [])
    assert matches == [["Applications", "SysLinuxOS Tools"]], matches
    print("OK: Applications → SysLinuxOS Tools → SysLinuxOS NVIDIA Setup (una sola voce)")
