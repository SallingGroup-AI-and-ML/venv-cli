from pathlib import Path
from shutil import copy2

import pytest

from tests.helpers import RequirementFiles


@pytest.fixture
def create_test_credentials(monkeypatch: pytest.MonkeyPatch) -> None:
    """Create test credentials for use in requirement files."""
    monkeypatch.setenv(name="TEST_USER", value="test-user")
    monkeypatch.setenv(name="TEST_PASS", value="test-pass")
    monkeypatch.setenv(name="TEST_TOKEN", value="test-token")


@pytest.fixture
def venv_dir(tmp_path: Path) -> RequirementFiles:
    """
    This fixture uses the temporary directory at 'tmp_path' supplied by pytest as the base directory
    for creating a virtual environment. It then copies all requirements files from 'tests/files' into
    the directory and returns a Files dictionary containing the path to the files in the temp dir.
    """
    src = Path.cwd() / "tests" / "files"
    dst = tmp_path

    files = RequirementFiles(
        {
            "base": dst,
            **{file.name: copy2(src=file, dst=dst / file.name) for file in src.glob("*requirements.*")},
        }
    )
    return files
