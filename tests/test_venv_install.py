import re
import subprocess
from itertools import chain
from pathlib import Path

import pytest
from pytest_cases import parametrize_with_cases

from tests.helpers import run_command, write_files
from tests.test_venv_install_cases import CasesVenvInstallRequirementstxt, CasesVenvInstallWithLock
from tests.types import RequirementsDict, RequirementsStem

_package_name_regex = re.compile(r"^([a-zA-Z0-9_-]+)\b")


def _check_package_was_installed(requirement: str, installed_line: str) -> None:
    """Check the 'Succesfully installed ...' output from 'pip install' to see that requirement was installed"""
    re_match = _package_name_regex.match(requirement)
    if re_match is None:
        raise ValueError(f"Could not extract package name from requirement '{requirement}'")

    package_name = re_match.group()
    assert package_name in installed_line, f"Package {package_name} was not installed succesfully"


def test_venv_install_not_activated(tmp_path: Path, monkeypatch: pytest.MonkeyPatch):
    with pytest.raises(subprocess.CalledProcessError), monkeypatch.context() as m:
        m.delenv("VIRTUAL_ENV", raising=False)
        run_command(["venv install"], cwd=tmp_path, activated=False)


@pytest.mark.order(after="test_venv_activate.py::test_venv_activate")
@parametrize_with_cases(argnames=["files", "requirements_stem"], cases=CasesVenvInstallRequirementstxt)
@pytest.mark.parametrize("use_file_name", [True, False])
def test_venv_install_requirements(
    files: RequirementsDict,
    requirements_stem: RequirementsStem,
    use_file_name: bool,
    tmp_path: Path,
    capfd: pytest.CaptureFixture,
):
    write_files(files=files, dir=tmp_path)

    # Install the requirements
    if not (requirements_stem is RequirementsStem.requirements or use_file_name):
        pytest.skip(f"Empty file name case only valid for requirements.txt, not {requirements_stem.value}.txt")

    install_file_name = ""
    if use_file_name:
        install_file_name = f"{requirements_stem.value}.txt"

    run_command(
        f"venv install {install_file_name} --skip-lock",
        cwd=tmp_path,
        activated=True,
    )

    # Check pip install log output
    output: str = capfd.readouterr().out
    assert f"Installing requirements from {requirements_stem.value}.txt" in output

    installed_line = [line for line in output.splitlines() if line.startswith("Successfully installed")][0]
    requirement_lines = chain.from_iterable(contents.splitlines() for contents in files.values())
    for requirement in requirement_lines:
        if requirement.startswith("-r"):
            # Skip '-r requirements.txt' line
            continue

        _check_package_was_installed(requirement=requirement, installed_line=installed_line)


@pytest.mark.order(after="test_venv_activate.py::test_venv_activate")
@parametrize_with_cases(argnames=["files", "requirements_stem"], cases=CasesVenvInstallWithLock)
def test_venv_install_with_lock(
    files: RequirementsDict,
    requirements_stem: RequirementsStem,
    tmp_path: Path,
):
    write_files(files=files, dir=tmp_path)

    run_command(
        f"venv install {requirements_stem}.txt",
        cwd=tmp_path,
        activated=True,
    )
