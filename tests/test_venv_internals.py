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
        (".", False),
        (".txt", False),
        (".lock", False),
        ("asdf", False),
        ("asdf.txt", False),
        ("asdf.lock", False),
        ("requirements", False),
        ("dev-requirements", False),
        ("requirements.asdf", False),
        ("dev-requirements.asdf", False),
        ("requirements.txtasdf", False),
        ("dev-requirements.lockasdf", False),
    ],
)
def test_venv_check_install_requirements_file(filename: str, expected: bool):
    """Check that 'venv::_check_install_requirements_file' works as expected"""
    command = f'venv::_check_install_requirements_file "{filename}"'

    if expected:
        run_command(command)
    else:
        with pytest.raises(subprocess.CalledProcessError):
            run_command(command)


def test_venv_check_install_requirements_file_quiet(capfd: pytest.CaptureFixture):
    """Check that 'venv::_check_install_requirements_file' can raise silently if called with -q"""
    # Call command with bad argument, not silenced
    with pytest.raises(subprocess.CalledProcessError):
        run_command('venv::_check_install_requirements_file "asdf.zip"')
    output = capfd.readouterr().out.strip()
    assert len(output) > 20

    # Call command with failing argument
    with pytest.raises(subprocess.CalledProcessError):
        run_command('venv::_check_install_requirements_file "asdf.zip" -q')
    output = capfd.readouterr().out.strip()
    assert output == ""


@pytest.mark.order("first")
@pytest.mark.parametrize(
    ["filename", "expected"],
    [
        ("requirements.lock", True),
        ("dev-requirements.lock", True),
        ("prod-requirements.lock", True),
        ("", False),
        (".", False),
        (".txt", False),
        (".lock", False),
        ("asdf", False),
        ("asdf.txt", False),
        ("asdf.lock", False),
        ("requirements", False),
        ("dev-requirements", False),
        ("requirements.txt", False),
        ("dev-requirements.txt", False),
        ("requirements.lockasdf", False),
        ("dev-requirements.lockasdf", False),
        ("requirements.asdf", False),
        ("dev-requirements.asdf", False),
    ],
)
def test_venv_check_lock_requirements_file(filename: str, expected: bool):
    """Check that 'venv::_check_lock_requirements_file' works as expected"""
    command = f'venv::_check_lock_requirements_file "{filename}"'

    if expected:
        run_command(command)
    else:
        with pytest.raises(subprocess.CalledProcessError):
            run_command(command)


def test_venv_check_lock_requirements_file_quiet(capfd: pytest.CaptureFixture):
    """Check that 'venv::_check_lock_requirements_file' can raise silently if called with -q"""
    # Call command with bad argument, not silenced
    with pytest.raises(subprocess.CalledProcessError):
        run_command('venv::_check_lock_requirements_file "asdf.zip"')
    output = capfd.readouterr().out.strip()
    assert len(output) > 20

    # Call command with failing argument
    with pytest.raises(subprocess.CalledProcessError):
        run_command('venv::_check_lock_requirements_file "asdf.zip" -q')
    output = capfd.readouterr().out.strip()
    assert output == ""


@pytest.mark.parametrize(
    ["filename", "expected"],
    [
        ("requirements", "requirements"),
        ("requirements.txt", "requirements.lock"),
        ("dev-requirements.txt", "dev-requirements.lock"),
        ("requirements.lock", "requirements.lock"),
        ("dev-requirements.lock", "dev-requirements.lock"),
    ],
)
def test_venv_get_lock_from_requirements(filename: str, expected: str, capfd: pytest.CaptureFixture):
    """Check that 'venv::_get_lock_from_requirements' works as expected"""
    run_command(f'venv::_get_lock_from_requirements "{filename}"')
    result = capfd.readouterr().out.strip()
    assert result == expected


@pytest.mark.parametrize(
    ["filename", "expected"],
    [
        ("requirements", "requirements"),
        ("requirements.lock", "requirements.txt"),
        ("dev-requirements.lock", "dev-requirements.txt"),
        ("requirements.txt", "requirements.txt"),
        ("dev-requirements.txt", "dev-requirements.txt"),
    ],
)
def test_venv_get_requirements_from_lock(filename: str, expected: str, capfd: pytest.CaptureFixture):
    """Check that 'venv::_get_requirements_from_lock' works as expected"""
    run_command(f'venv::_get_requirements_from_lock "{filename}"')
    result = capfd.readouterr().out.strip()
    assert result == expected
