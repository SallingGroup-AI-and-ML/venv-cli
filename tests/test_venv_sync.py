from pathlib import Path

import pytest

from tests.helpers import RequirementFiles, run_command


@pytest.mark.order(
    after=[
        "test_venv_install.py::test_venv_install",
        "test_venv_clear.py::test_venv_clear",
    ]
)
@pytest.mark.parametrize(
    "lock_file",
    [
        "",
        "requirements.lock",
        "dev-requirements.lock",
    ],
)
def test_venv_sync(lock_file: str, venv_dir: RequirementFiles, capfd: pytest.CaptureFixture):
    """Checks that we can run 'venv sync' to clear the environment and then install locked requirements"""
    lock_file_path: str | Path = venv_dir.get(lock_file, lock_file)

    run_command(commands=[f"venv sync {lock_file_path}"], activated=True, cwd=venv_dir["base"])

    captured = capfd.readouterr()
    assert "Removing all packages" in captured.out
    assert "All packages removed" in captured.out
    assert "Installing requirements from" in captured.out
