import re
from pathlib import Path

import pytest

from tests.helpers import run_command


@pytest.mark.parametrize("arg", ["-V", "--version"])
def test_venv_help(arg: str, tmp_path: Path, capfd: pytest.CaptureFixture):
    """Checks that we can show the version number"""
    run_command(f"venv {arg}", cwd=tmp_path)

    captured = capfd.readouterr()
    assert re.search(r"venv-cli\s\d+?\.\d+?\.\d+?", captured.out)
