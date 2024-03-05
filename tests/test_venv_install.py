import itertools
import re
import subprocess
from collections.abc import Collection
from itertools import chain
from pathlib import Path

import pytest
from pytest_cases import parametrize, parametrize_with_cases

from tests.helpers import run_command, write_files
from tests.test_venv_install_cases import (
    CasesVenvAddPackagesToRequirements,
    CasesVenvInstallRequirementstxt,
    CasesVenvInstallWithLock,
)
from tests.types import PackageName, PackageSpec, RequirementsDict, RequirementsStem

_package_name_regex = re.compile(r"^([a-zA-Z0-9_-]+)\b")


def _check_package_was_installed(requirement: str, installed_line: str) -> None:
    """Check the 'Succesfully installed ...' output from 'pip install' to see that requirement was installed"""
    re_match = _package_name_regex.match(requirement)
    if re_match is None:
        raise ValueError(f"Could not extract package name from requirement '{requirement}'")

    package_name = re_match.group()
    assert package_name in installed_line, f"Package {package_name} was not installed succesfully"


def _check_packages_in_requirements_txt(packages: Collection[str], requirements_file: Path) -> None:
    """Check that the package was added to the requirements file"""
    requirements = requirements_file.read_text().strip()
    for package in packages:
        assert package in requirements, f"Package {package} was not added to requirements.txt"


def test_venv_install_not_activated(tmp_path: Path, monkeypatch: pytest.MonkeyPatch):
    with pytest.raises(subprocess.CalledProcessError), monkeypatch.context() as m:
        m.delenv("VIRTUAL_ENV", raising=False)
        run_command(["venv install"], cwd=tmp_path, activated=False)


_pjl = ["python-json-logger", "python-json-logger==2.0.7", "'python-json-logger == 2.0.7'"]
_urllib = ["urllib3", "urllib3==2.2.1", "'urllib3 == 2.2.1'"]
_wheel = ["wheel", "wheel==0.42.0", "'wheel == 0.42.0'"]


@pytest.mark.order(after="test_venv_activate.py::test_venv_activate")
@parametrize(
    ["package_spec", "expected_packages"],
    [
        *itertools.product(itertools.product(_pjl), [("python-json-logger",)]),
        *itertools.product(itertools.product(_pjl, _urllib), [("python-json-logger", "urllib3")]),
        *itertools.product(itertools.product(_pjl, _urllib, _wheel), [("python-json-logger", "urllib3", "wheel")]),
    ],
)
def test_venv_install_packages(
    package_spec: tuple[str, ...],
    expected_packages: tuple[str, ...],
    tmp_path: Path,
    capfd: pytest.CaptureFixture[str],
):
    # Install the requirements
    run_command(
        f"venv install {' '.join(package_spec)} --skip-lock",
        cwd=tmp_path,
        activated=True,
    )

    # Check pip install log output
    output = capfd.readouterr().out
    assert f"Installing" in output

    # Check that the expected packages were installed
    installed_line = [line for line in output.splitlines() if line.startswith("Successfully installed")][0]
    for package in expected_packages:
        _check_package_was_installed(requirement=package, installed_line=installed_line)

    # Check that the expected packages were added to requirements.txt
    _check_packages_in_requirements_txt(packages=expected_packages, requirements_file=tmp_path / "requirements.txt")


@parametrize_with_cases(argnames=["files", "requirements"], cases=CasesVenvAddPackagesToRequirements)
def test_add_packages_to_requirements(
    files: RequirementsDict,
    requirements: tuple[RequirementsStem, list[tuple[PackageName, PackageSpec]]],
    tmp_path: Path,
    capfd: pytest.CaptureFixture[str],
):
    write_files(files=files, dir=tmp_path)

    requirements_stem, name_spec = requirements
    requirements_filename = f"{requirements_stem.value}.txt"

    _, package_specs = zip(*name_spec)
    package_spec_str = " ".join(f"'{package_spec}'" for package_spec in package_specs)

    run_command(
        f"venv::_add_packages_to_requirements {requirements_filename} {package_spec_str}",
        cwd=tmp_path,
        activated=True,
    )
    new_contents = (tmp_path / requirements_filename).read_text().strip()

    output = capfd.readouterr().out
    for package_name, package_spec in name_spec:
        assert f"Adding '{package_spec}' to {requirements_filename}" in output
        assert package_spec in new_contents, f"Package {package_name} was not added to {requirements_filename}"


@pytest.mark.order(after="test_venv_activate.py::test_venv_activate")
@parametrize_with_cases(argnames=["files", "requirements_stem"], cases=CasesVenvInstallRequirementstxt)
def test_venv_install_requirements(
    files: RequirementsDict,
    requirements_stem: RequirementsStem,
    tmp_path: Path,
    capfd: pytest.CaptureFixture[str],
):
    write_files(files=files, dir=tmp_path)

    # Install the requirements
    run_command(
        f"venv install -r {requirements_stem.value}.txt --skip-lock",
        cwd=tmp_path,
        activated=True,
    )

    # Check pip install log output
    output = capfd.readouterr().out
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
def test_venv_install_requirements_with_lock(
    files: RequirementsDict,
    requirements_stem: RequirementsStem,
    tmp_path: Path,
):
    write_files(files=files, dir=tmp_path)

    run_command(
        f"venv install -r {requirements_stem}.txt",
        cwd=tmp_path,
        activated=True,
    )

    assert (tmp_path / f"{requirements_stem}.lock").exists()
