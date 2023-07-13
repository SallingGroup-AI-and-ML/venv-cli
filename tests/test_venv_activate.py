from pathlib import Path

import pytest

from test_venv_create import test_venv_create
from tests.helpers import run_command


@pytest.mark.order(after="test_venv_create.py::test_venv_create")
def test_venv_activate(tmp_path: Path):
    """Checks that we can create and activate an environment"""
    test_venv_create(tmp_path)
    run_command("venv activate", cwd=tmp_path)
