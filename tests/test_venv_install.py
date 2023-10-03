import re
from pathlib import Path

import pytest
from pytest_cases import parametrize_with_cases

from tests.helpers import run_command
from tests.test_venv_install_cases import CasesVenvInstallDevRequirementstxt, CasesVenvInstallRequirementstxt

_package_regex = re.compile(r"^([a-zA-Z0-9_-]+)\b")


@pytest.mark.order(after="test_venv_activate.py::test_venv_activate")
@pytest.mark.parametrize("command_arg", ["", "requirements.txt"])
@parametrize_with_cases(argnames=["files"], cases=CasesVenvInstallRequirementstxt)
def test_venv_install_requirements_txt(
    command_arg: str,
    files: dict[str, str],
    tmp_path: Path,
    capfd: pytest.CaptureFixture,
):
    (tmp_path / "requirements.txt").write_text(files["requirements.txt"])

    # Install the requirements
    run_command(f"venv install {command_arg} --skip-lock", cwd=tmp_path, activated=True)

    # Check pip install log output
    output: str = capfd.readouterr().out
    assert "Installing requirements from requirements.txt" in output

    installed_line = [line for line in output.splitlines() if line.startswith("Successfully installed")][0]
    for requirement in files["requirements.txt"].splitlines():
        re_match = _package_regex.match(requirement)
        if re_match is None:
            raise ValueError(f"Could not extract package name from requirement '{requirement}'")

        package_name = re_match.group()
        assert package_name in installed_line


@pytest.mark.order(after="test_venv_activate.py::test_venv_activate")
@parametrize_with_cases(argnames=["files"], cases=CasesVenvInstallDevRequirementstxt)
def test_venv_install_dev_requirements_txt(
    files: dict[str, str],
    tmp_path: Path,
    capfd: pytest.CaptureFixture,
):
    for file_name, contents in files.items():
        (tmp_path / file_name).write_text(contents)

    # Install the requirements
    run_command("venv install dev-requirements.txt --skip-lock", cwd=tmp_path, activated=True)

    # Check pip install log output
    output: str = capfd.readouterr().out
    assert "Installing requirements from dev-requirements.txt" in output

    installed_line = [line for line in output.splitlines() if line.startswith("Successfully installed")][0]
    for requirement in [
        *files["requirements.txt"].splitlines(),
        *files["dev-requirements.txt"].splitlines(),
    ]:
        if requirement.startswith("-r"):
            # Skip '-r requirements.txt' line
            continue

        _check_package_was_installed(requirement=requirement, installed_line=installed_line)


def _check_package_was_installed(requirement: str, installed_line: str) -> None:
    re_match = _package_regex.match(requirement)
    if re_match is None:
        raise ValueError(f"Could not extract package name from requirement '{requirement}'")

    package_name = re_match.group()
    assert package_name in installed_line
