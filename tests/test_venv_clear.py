from pathlib import Path

import pytest

from tests.helpers import run_command


@pytest.mark.order(after="test_venv_install.py::test_venv_install")
def test_venv_clear(tmp_path: Path, capfd: pytest.CaptureFixture):
    """Checks that we can clear installed packages in an environment after installing them"""
    run_command(commands=["venv install", "venv clear"], activated=True, cwd=tmp_path)

    captured = capfd.readouterr()
    assert "Removing all packages" in captured.out
    assert "All packages removed" in captured.out
