from pathlib import Path

import pytest

from tests.helpers import run_command


@pytest.mark.order(after="test_venv_activate.py::test_venv_activate")
def test_venv_deactivate(tmp_path: Path):
    """Checks that we can create, activate and deactivate an environment"""
    run_command("venv deactivate", activated=True, cwd=tmp_path)


def test_venv_deactivate_noop(tmp_path: Path, capfd: pytest.CaptureFixture):
    """Checks that trying to deactivate an environment that is not activated does nothing"""
    run_command("venv deactivate", cwd=tmp_path)

    captured = capfd.readouterr()
    assert "No virtual environment currently active, nothing to deactivate" in captured.out
