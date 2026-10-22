import os
import subprocess
from pathlib import Path

import pytest

from tests.helpers import current_python_version, run_command


def test_venv_create_python_not_specified(tmp_path: Path):
    """Checks that creating an environment without specifying python version fails"""
    with pytest.raises(subprocess.CalledProcessError):
        run_command("venv create", cwd=tmp_path)


def test_venv_create_python_not_installed(tmp_path: Path):
    """Checks that creating an environment with a version of python that doesn't exist on the system fails"""
    with pytest.raises(subprocess.CalledProcessError):
        run_command("venv create 5.1", cwd=tmp_path)


@pytest.mark.order(after="test_venv_source.py::test_venv_source")
def test_venv_create(tmp_path: Path):
    """Checks that we can create an environment using the version of python that is currently being used"""
    run_command(f"venv create {current_python_version}", cwd=tmp_path)
    assert (tmp_path / ".venv" / "bin" / "python").exists()


@pytest.mark.order(after="test_venv_source.py::test_venv_source")
@pytest.mark.parametrize("venv_name", ["my-venv", "another-env"])
def test_venv_create_name(venv_name: str, tmp_path: Path):
    """Checks that we can create an environment using the version of python that is currently being used"""
    run_command(f"venv create {current_python_version} {venv_name}", cwd=tmp_path)

    with (tmp_path / ".venv" / "pyvenv.cfg").open("r") as config:
        prompt_config = [line for line in config.read().splitlines() if "prompt" in line][0]
        actual_prompt = prompt_config.removeprefix("prompt = '").removesuffix("'")

    assert actual_prompt == venv_name


@pytest.fixture
def mock_python(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    python = bin_dir / f"python{current_python_version}"
    python.write_text(
        "#!/bin/sh\n"
        'if [ "$1" = "-V" ]; then echo "Python test"; exit 0; fi\n'
        'printf "%s\\n" "$@" > create-args\n'
        'if [ -n "$CREATE_EXIT_CODE" ]; then\n'
        '  echo "Environment creation failed" >&2\n'
        '  exit "$CREATE_EXIT_CODE"\n'
        "fi\n"
        "mkdir -p .venv/bin\n"
        'cp "$(dirname "$0")/mock-pip" .venv/bin/python\n'
    )
    python.chmod(0o755)
    pip = bin_dir / "mock-pip"
    pip.write_text(
        "#!/bin/sh\n"
        'printf "%s\\n" "$@" > pip-args\n'
        'if [ -n "$PIP_EXIT_CODE" ]; then\n'
        '  echo "Pip upgrade failed" >&2\n'
        '  exit "$PIP_EXIT_CODE"\n'
        "fi\n"
    )
    pip.chmod(0o755)
    monkeypatch.setenv("PATH", f"{bin_dir}{os.pathsep}{os.environ['PATH']}")


def test_venv_create_flag_before_version(tmp_path: Path, mock_python: None):
    run_command(f"venv create --no-pip-upgrade {current_python_version}", cwd=tmp_path)
    assert (tmp_path / "create-args").exists()
    assert not (tmp_path / "pip-args").exists()


@pytest.mark.parametrize("args", ["--no-pip-upgrade", "--invalid"])
def test_venv_create_invalid_args(args: str, tmp_path: Path, mock_python: None):
    with pytest.raises(subprocess.CalledProcessError):
        run_command(f"venv create {args}", cwd=tmp_path)
    assert not (tmp_path / "create-args").exists()


def test_venv_create_help_documents_pip_upgrade(tmp_path: Path, capfd: pytest.CaptureFixture[str]):
    run_command("venv create --help", cwd=tmp_path)
    output = capfd.readouterr().out
    assert "--no-pip-upgrade" in output
    assert "pip is upgraded" in output
