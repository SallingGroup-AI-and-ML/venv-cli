from pathlib import Path

import pytest

from tests.helpers import run_command
from tests.test_venv_create import test_venv_create


@pytest.mark.order(after="test_venv_create.py::test_venv_create")
def test_venv_activate(tmp_path: Path):
    """Checks that we can create and activate an environment"""
    test_venv_create(tmp_path)
    run_command("venv activate", cwd=tmp_path)
