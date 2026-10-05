"""Build distribution artifacts in a temporary copy without installing them."""
import pathlib
import shutil
import subprocess
import tarfile
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]


class PackagingTests(unittest.TestCase):
    def test_distribution_excludes_git_metadata_and_has_valid_checksums(self):
        with tempfile.TemporaryDirectory() as directory:
            project = pathlib.Path(directory) / "project"
            shutil.copytree(
                ROOT, project,
                ignore=shutil.ignore_patterns(".git", "dist", "__pycache__", "*.pyc"),
            )
            (project / ".git").mkdir()
            (project / ".git/config").write_text("private metadata sentinel\n")
            result = subprocess.run(
                ["bash", "build-deb.sh"], cwd=project,
                text=True, capture_output=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            archives = list((project / "dist").glob("*.tar.gz"))
            self.assertEqual(len(archives), 1)
            with tarfile.open(archives[0]) as archive:
                self.assertFalse(any(
                    ".git" in pathlib.PurePosixPath(name).parts
                    for name in archive.getnames()
                ), "Source archives must not contain local Git metadata")
            result = subprocess.run(
                ["sha256sum", "--check", "SHA256SUMS"], cwd=project / "dist",
                text=True, capture_output=True,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
