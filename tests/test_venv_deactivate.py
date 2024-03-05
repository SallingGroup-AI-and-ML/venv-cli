from pathlib import Path

import pytest

from tests.helpers import run_command


@pytest.mark.order(after="test_venv_activate.py::test_venv_activate")
def test_venv_deactivate(tmp_path: Path):
    """Checks that we can create, activate and deactivate an environment"""
    run_command("venv deactivate", activated=True, cwd=tmp_path)
