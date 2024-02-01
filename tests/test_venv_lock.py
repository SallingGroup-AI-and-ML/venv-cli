import subprocess
from pathlib import Path

import pytest
from pytest_cases import parametrize, parametrize_with_cases

from tests.helpers import run_command, write_files
from tests.test_venv_lock_cases import CasesVenvLock
from tests.types import RequirementsDict, RequirementsStem


@pytest.mark.order(
    after=[
        "test_venv_install.py::test_venv_install",
        "test_venv_fill_credentials.py::test_venv_fill_credentials",
    ]
)
@parametrize_with_cases(argnames=["files", "requirements_stem"], cases=CasesVenvLock)
@parametrize("use_short_name", [False, True])
def test_venv_lock(
    files: RequirementsDict,
    requirements_stem: RequirementsStem,
    use_short_name: bool,
    tmp_path: Path,
):
    """Checks that we can lock requirements in an environment after installing them"""
    write_files(files=files, dir=tmp_path)

    lock_file_path = f"{requirements_stem}.lock"
    if use_short_name:
        lock_file_arg = requirements_stem.split("-")[0] if "-" in requirements_stem else ""
    else:
        lock_file_arg = lock_file_path

    run_command(
        commands=[
            f"venv install {requirements_stem}.txt --skip-lock",
            f"venv lock {lock_file_arg}",
        ],
        cwd=tmp_path,
        activated=True,
    )

    lock_file_contents = (tmp_path / lock_file_path).read_text().splitlines()
    assert lock_file_contents == files[lock_file_path].splitlines()


@parametrize(
    "lock_arg",
    [
        "file.txt",
        "requirements.txt",
        "requirements.asd",
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
def test_venv_lock_echo(tmp_path: Path, capfd: pytest.CaptureFixture):
    """Checks that 'venv lock' echoes a message when executed"""
    run_command("venv lock", activated=True, cwd=tmp_path)

    output = capfd.readouterr().out
    assert "Locked requirements in" in output
