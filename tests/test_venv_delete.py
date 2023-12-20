from pathlib import Path

import pytest
import pytest_cases

from tests.helpers import run_command


@pytest.mark.order(after="test_venv_activate.py::test_venv_activate")
@pytest_cases.parametrize("yes", ["y", "yes", "Y", "Yes", "YES"])
@pytest_cases.parametrize("activated", [False, True])
def test_venv_delete_ask_confirmation_yes(activated: bool, yes: str, tmp_path: Path):
    venv_path = tmp_path / ".venv"

    # Execute: Create, then delete, the virtual environment
    run_command("venv delete", command_input=yes, cwd=tmp_path, activated=activated)

    # Verify: check that the virtual environment directory no longer exists
    assert not venv_path.is_dir()

    # Test that trying to delete again doesn't cause an error
    run_command("venv delete", command_input=yes, cwd=tmp_path, activated=activated)


@pytest.mark.order(after="test_venv_activate.py::test_venv_activate")
@pytest_cases.parametrize("no", ["", "n", "N", "No", "NO", "asd"])
@pytest_cases.parametrize("activated", [False, True])
def test_venv_delete_ask_confirmation_no(activated: bool, no: str, tmp_path: Path):
    venv_path = tmp_path / ".venv"

    # Execute: Create, then try to delete, the virtual environment, but say no
    run_command("venv delete", command_input=no, cwd=tmp_path, activated=activated)

    if activated:
        # Verify: check that the virtual environment directory still exists (if it was created)
        assert venv_path.is_dir()


@pytest.mark.order(after="test_venv_activate.py::test_venv_activate")
@pytest_cases.parametrize("activated", [False, True])
def test_venv_delete_no_confirmation(activated: bool, tmp_path: Path):
    venv_path = tmp_path / ".venv"

    # Execute: Create, then delete, the virtual environment
    run_command("venv delete -y", cwd=tmp_path, activated=activated)

    # Verify: check that the virtual environment directory no longer exists
    assert not venv_path.is_dir()

    # Test that trying to delete again doesn't cause an error
    run_command("venv delete -y", cwd=tmp_path, activated=activated)
