import subprocess

import pytest

from tests.helpers import run_command


@pytest.mark.order("first")
@pytest.mark.parametrize(
    ["filename", "expected"],
    [
        ("requirements.txt", True),
        ("requirements.lock", True),
        ("dev-requirements.txt", True),
        ("dev-requirements.lock", True),
        ("prod-requirements.txt", True),
        ("prod-requirements.lock", True),
        ("", False),
        ("asdf", False),
        ("asdf.txt", False),
        ("asdf.lock", False),
        ("requirements", False),
        ("dev-requirements", False),
        ("requirements.asdf", False),
        ("dev-requirements.asdf", False),
        (".", False),
        (".txt", False),
        (".lock", False),
    ],
)
def test_venv_check_install_requirements_file(filename: str, expected: bool):
    """Check that 'venv::_check_install_requirements_file' works as expected"""
    command = f"venv::_check_install_requirements_file {filename}"

    if expected:
        run_command(command)
    else:
        with pytest.raises(subprocess.CalledProcessError):
            run_command(command)


@pytest.mark.order("first")
@pytest.mark.parametrize(
    ["filename", "expected"],
    [
        ("requirements.lock", True),
        ("dev-requirements.lock", True),
        ("prod-requirements.lock", True),
        ("", False),
        ("asdf", False),
        ("asdf.txt", False),
        ("asdf.lock", False),
        ("requirements", False),
        ("dev-requirements", False),
        ("requirements.txt", False),
        ("dev-requirements.txt", False),
        ("prod-requirements.txt", False),
        ("requirements.asdf", False),
        ("dev-requirements.asdf", False),
        (".", False),
        (".txt", False),
        (".lock", False),
    ],
)
def test_venv_check_lock_requirements_file(filename: str, expected: bool):
    """Check that 'venv::_check_lock_requirements_file' works as expected"""
    command = f"venv::_check_lock_requirements_file {filename}"

    if expected:
        run_command(command)
    else:
        with pytest.raises(subprocess.CalledProcessError):
            run_command(command)
