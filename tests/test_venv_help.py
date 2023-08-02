from pathlib import Path

import pytest

from tests.helpers import run_command


@pytest.mark.parametrize("arg", ["", "-h", "--help"])
def test_venv_help(arg: str, tmp_path: Path, capfd: pytest.CaptureFixture):
    """Checks that we can get the help menu for the main 'venv' command"""
    run_command(f"venv {arg}", cwd=tmp_path)

    output = capfd.readouterr().out
    assert "Utility to help create and manage python virtual environments" in output
    assert "Syntax:" in output
    assert "available commands" in output
    assert "Show this help" in output


@pytest.mark.parametrize(
    "command",
    [
        "create",
        "activate",
        "deactivate",
        "install",
        "lock",
        "clear",
        "sync",
    ],
)
@pytest.mark.parametrize("help_arg", ["-h", "--help"])
def test_venv_command_help(command: str, help_arg: str, tmp_path: Path, capfd: pytest.CaptureFixture):
    """Checks that we can get the help menu for 'venv <command>'"""
    run_command(f"venv {command} {help_arg}", cwd=tmp_path)

    output = capfd.readouterr().out
    assert f"venv {command}" in output
    assert "Examples" in output
