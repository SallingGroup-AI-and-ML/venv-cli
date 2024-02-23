import re

import pytest

from tests.helpers import run_command

_version_pattern = re.compile(r"^venv-cli v\d+\.\d+\.\d+.*$")


@pytest.mark.parametrize("arg", ["-V", "--version"])
def test_venv_version(arg: str, capfd: pytest.CaptureFixture[str]):
    """Checks that we can show the version number, and that the version number
    complies with the required pattern"""
    run_command(f"venv {arg}")

    output = capfd.readouterr().out
    assert re.match(_version_pattern, output.strip())
