import subprocess

import pytest

from tests.helpers import run_command


@pytest.mark.order("first")
@pytest.mark.parametrize("message", ["", '"This is an error"'])
def test_venv_raise(message: str, capfd: pytest.CaptureFixture[str]):
    with pytest.raises(subprocess.CalledProcessError):
        run_command(f"venv::raise {message}")

    output = capfd.readouterr().out
    assert message.replace('"', "") in output
