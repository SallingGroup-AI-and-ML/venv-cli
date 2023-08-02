import subprocess
from pathlib import Path

import pytest

from tests.helpers import RequirementFiles, run_command


@pytest.mark.order(
    after=[
        "test_venv_install.py::test_venv_install",
        "test_venv_fill_credentials.py::test_venv_fill_credentials",
    ]
)
@pytest.mark.parametrize(
    # fmt: off
    [    "install_file",         "lock_arg",              "lock_file"],
    [
        ("",                     "",                      "requirements.lock"),
        ("",                     "requirements.lock",     "requirements.lock"),
        ("requirements.txt",     "",                      "requirements.lock"),
        ("requirements.txt",     "requirements.lock",     "requirements.lock"),
        ("dev-requirements.txt", "dev",                   "dev-requirements.lock"),
        ("dev-requirements.txt", "dev-requirements.lock", "dev-requirements.lock"),
    ],
    # fmt: on
)
def test_venv_lock(
    install_file: str,
    lock_arg: str,
    lock_file: str,
    venv_dir: RequirementFiles,
    create_test_credentials: None,
):
    """Checks that we can lock requirements in an environment after installing them"""
    install_file_path: str | Path = venv_dir.get(install_file, install_file)

    run_command(
        commands=[
            f"venv install {install_file_path}",
            f"venv lock {lock_arg}",
        ],
        activated=True,
        cwd=venv_dir["base"],
    )

    lock_file_path = venv_dir[lock_file]
    contents = lock_file_path.read_text().splitlines()
    assert all(("==" in line or " @ git+http" in line) for line in contents)


@pytest.mark.parametrize(
    "lock_arg",
    [
        "file.lock",
        "requirements.txt",
        "requirements.asd",
        "requirements.lock requirements.txt",  # Requirements and lock files switched
        "dev",  # Reference file 'dev-requirements.txt' doesn't exist
        "dev-requirements.lock",  # Reference file 'dev-requirements.txt' doesn't exist
    ],
)
def test_venv_lock_raises(lock_arg: str, tmp_path: Path):
    """Checks that 'venv lock' raises correct exceptions"""
    with pytest.raises(subprocess.CalledProcessError):
        run_command(commands=f"venv lock {lock_arg}", activated=False, cwd=tmp_path)


@pytest.mark.order(
    after=[
        "test_venv_install.py::test_venv_install",
        "test_venv_fill_credentials.py::test_venv_fill_credentials",
    ]
)
def test_venv_lock_echo(venv_dir: RequirementFiles, capfd: pytest.CaptureFixture):
    """Checks that 'venv lock' echoes a message when executed"""
    run_command("venv lock", activated=True, cwd=venv_dir["base"])

    output = capfd.readouterr().out
    assert "Locked requirements in" in output
