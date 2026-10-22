import itertools
import re
import subprocess
from collections.abc import Collection
from itertools import chain
from pathlib import Path
from shlex import quote

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
_package_installed_regex = re.compile(r"^Successfully installed (?!pip-[0-9]+.*$)(.+)$")


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


_mock_install_commands = [
    "venv::clear() { touch clear-called; }",
    'pip() { printf "%s\\n" "$@" > pip-args; return "${PIP_EXIT_CODE:-0}"; }',
    'venv::lock() { printf "%s\\n" "$@" > lock-args; }',
]


@pytest.mark.parametrize(
    "constraint_args",
    [
        [],
        ["-c", "constraints.txt"],
        ["--constraint", "constraints.txt"],
        ["-c", "constraints with spaces"],
        ["--constraint", "constraints' file"],
        ["-c", "first.txt", "--constraint", "second.lock"],
    ],
)
def test_venv_install_constraints(constraint_args: list[str], tmp_path: Path):
    (tmp_path / "requirements.txt").write_text("")
    args = " ".join(quote(arg) for arg in constraint_args)
    run_command(
        [
            *_mock_install_commands,
            f"venv install demo-package -r requirements.txt {args} --pip-args='--no-cache-dir --pre'",
        ],
        cwd=tmp_path,
    )

    assert (tmp_path / "pip-args").read_text().splitlines() == [
        "install",
        "--require-virtualenv",
        "--use-pep517",
        "-r",
        "requirements.txt",
        *constraint_args,
        "--no-cache-dir",
        "--pre",
    ]
    assert (tmp_path / "requirements.txt").read_text() == "demo-package\n"
    assert (tmp_path / "lock-args").read_text() == "requirements.lock\n"


@pytest.mark.parametrize("command", ["install", "uninstall demo-package"])
@pytest.mark.parametrize(
    ("pip_args", "expected_args"),
    [
        (None, []),
        ("", []),
        (" \t\n ", []),
        ("--pre", ["--pre"]),
        ("--no-cache-dir --pre", ["--no-cache-dir", "--pre"]),
        (" \t--no-cache-dir \n --pre\t ", ["--no-cache-dir", "--pre"]),
    ],
)
def test_venv_install_pip_args(command: str, pip_args: str | None, expected_args: list[str], tmp_path: Path):
    (tmp_path / "requirements.txt").write_text("demo-package\n")
    option = "" if pip_args is None else f"--pip-args={quote(pip_args)}"
    run_command(
        [*_mock_install_commands, f"venv {command} -r requirements.txt {option}"],
        cwd=tmp_path,
    )

    assert (tmp_path / "pip-args").read_text().splitlines() == [
        "install",
        "--require-virtualenv",
        "--use-pep517",
        "-r",
        "requirements.txt",
        *expected_args,
    ]
    assert (tmp_path / "lock-args").read_text() == "requirements.lock\n"


@pytest.mark.parametrize("flag", ["-c", "--constraint"])
def test_venv_install_constraint_requires_filename(flag: str, tmp_path: Path):
    with pytest.raises(subprocess.CalledProcessError):
        run_command([*_mock_install_commands, f"venv install {flag}"], cwd=tmp_path)
    assert not (tmp_path / "clear-called").exists()
    assert not (tmp_path / "pip-args").exists()


def test_venv_install_constraint_pip_failure(tmp_path: Path, monkeypatch: pytest.MonkeyPatch):
    monkeypatch.setenv("PIP_EXIT_CODE", "1")
    with pytest.raises(subprocess.CalledProcessError):
        run_command(
            [*_mock_install_commands, "venv install -c missing.txt"],
            cwd=tmp_path,
        )
    assert (tmp_path / "pip-args").exists()
    assert not (tmp_path / "lock-args").exists()


def test_venv_install_help_documents_constraints(tmp_path: Path, capfd: pytest.CaptureFixture[str]):
    run_command("venv install --help", cwd=tmp_path)
    assert "-c, --constraint <constraints file>" in capfd.readouterr().out


_pjl = ["python-json-logger", "python-json-logger==2.0.7", "'python-json-logger == 2.0.7'"]
_urllib = ["urllib3", "urllib3==2.2.1", "'urllib3 == 2.2.1'"]
_attrs = ["attrs", "attrs==25.4.0", "'attrs == 25.4.0'"]


@pytest.mark.order(after="test_venv_activate.py::test_venv_activate")
@parametrize(
    ["package_spec", "expected_packages"],
    [
        *itertools.product(itertools.product(_pjl), [("python-json-logger",)]),
        *itertools.product(itertools.product(_pjl, _urllib), [("python-json-logger", "urllib3")]),
        *itertools.product(itertools.product(_pjl, _urllib, _attrs), [("python-json-logger", "urllib3", "attrs")]),
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
    installed_line = [line for line in output.splitlines() if _package_installed_regex.match(line)][0]
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

    installed_line = [line for line in output.splitlines() if _package_installed_regex.match(line)][0]
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
        f"venv install -r {requirements_stem.value}.txt",
        cwd=tmp_path,
        activated=True,
    )

    assert (tmp_path / f"{requirements_stem.value}.lock").exists()
