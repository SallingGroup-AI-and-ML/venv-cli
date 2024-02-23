from pathlib import Path

import pytest

from tests.helpers import run_command


@pytest.mark.order(after="test_venv_install.py::test_venv_install")
def test_venv_clear(tmp_path: Path, capfd: pytest.CaptureFixture[str]):
    """Checks that we can clear installed packages in an environment after installing them"""
    run_command(commands=["venv install --skip-lock", "venv clear"], activated=True, cwd=tmp_path)

    output = capfd.readouterr().out
    assert "Removing all packages" in output
    assert "All packages removed" in output
