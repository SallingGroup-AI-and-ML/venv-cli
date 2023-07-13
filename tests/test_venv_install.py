from pathlib import Path

import pytest

from tests.helpers import Files, run_command


@pytest.mark.order(after="test_venv_activate.py::test_venv_activate")
@pytest.mark.parametrize(
    "file",
    [
        "",
        "requirements.txt",
        "dev-requirements.txt",
        "requirements.lock",
        "dev-requirements.lock",
    ],
)
def test_venv_install(file: str, venv_dir: Files):
    """Checks that we can create, activate and deactivate an environment"""
    file_path: str | Path = venv_dir.get(file, file)

    run_command(f"venv install {file_path}", activated=True, cwd=venv_dir["base"])
