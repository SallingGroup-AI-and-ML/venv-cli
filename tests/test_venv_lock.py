from pathlib import Path

import pytest

from tests.helpers import Files, run_command


@pytest.mark.order(after="test_venv_install.py::test_venv_install")
@pytest.mark.parametrize(
    ["install_file", "lock_arg", "lock_file"],
    [
        ("", "", "requirements.lock"),
        ("", "requirements.lock", "requirements.lock"),
        ("requirements.txt", "", "requirements.lock"),
        ("requirements.txt", "requirements.lock", "requirements.lock"),
        ("dev-requirements.txt", "dev", "dev-requirements.lock"),
        ("dev-requirements.txt", "dev-requirements.lock", "dev-requirements.lock"),
    ],
)
def test_venv_lock(install_file: str, lock_arg: str, lock_file: str, venv_dir: Files):
    """Checks that we can lock requirements in an environment after installing them"""
    install_file_path: str | Path = venv_dir.get(install_file, install_file)
    lock_file_path: Path = venv_dir[lock_file]

    run_command(
        commands=[
            f"venv install {install_file_path}",
            f"venv lock {lock_arg}",
        ],
        activated=True,
        cwd=venv_dir["base"],
    )

    with Path(lock_file_path).open("r") as locked_file:
        contents = locked_file.read().splitlines()
    assert all("==" in line for line in contents)


@pytest.mark.order(after="test_venv_install.py::test_venv_install")
def test_venv_lock_echo(tmp_path: Path, capfd: pytest.CaptureFixture):
    """Checks that 'venv lock' echoes a message when executed"""
    run_command("venv lock", activated=True, cwd=tmp_path)

    captured = capfd.readouterr()
    assert "Locked requirements in" in captured.out
