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


@pytest.mark.order(after="test_venv_source.py::test_venv_source")
@pytest.mark.parametrize("venv_name", ["my-venv", "another-env"])
def test_venv_create_name(venv_name: str, tmp_path: Path):
    """Checks that we can create an environment using the version of python that is currently being used"""
    run_command(f"venv create {current_python_version} {venv_name}", cwd=tmp_path)

    with (tmp_path / ".venv" / "pyvenv.cfg").open("r") as config:
        prompt_config = [line for line in config.read().splitlines() if "prompt" in line][0]
        actual_prompt = prompt_config.removeprefix("prompt = '").removesuffix("'")

    expected_prompt = f"{venv_name}"
    assert expected_prompt == actual_prompt
