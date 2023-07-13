from pathlib import Path

import pytest

from tests.helpers import run_command


@pytest.mark.order("first")
def test_venv_source(tmp_path: Path):
    """Checks that simply sourcing the venv source script works"""
    run_command("", cwd=tmp_path)
