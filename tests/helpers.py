import os
import subprocess
import sys
from functools import wraps
from pathlib import Path
from typing import Callable

from tests.types import P, RawFilesDict, RequirementsBase, RequirementsDict

RequirementFiles = dict[str, Path]
current_python_version = f"{sys.version_info.major}.{sys.version_info.minor}"
_venv_cli_path = Path.cwd() / "src" / "venv-cli" / "venv.sh"


def _command_setup(venv_cli_path: Path, activate: bool = False) -> list[str]:
    bash = [os.environ["SHELL"], "-c"]
    source_command = f". {venv_cli_path}"

    additional_commands: list[str] = []
    if activate:
        additional_commands = [
            f"venv create {current_python_version}",
            "venv activate",
        ]

    full_command = "; ".join([source_command, *additional_commands]) + "; "
    return [*bash, full_command]


def run_command(commands: str | list[str], cwd: Path = Path.cwd(), activated: bool = False) -> None:
    input_commands = [commands] if isinstance(commands, str) else commands

    setup_commands = _command_setup(venv_cli_path=_venv_cli_path, activate=activated)
    all_commands = [*setup_commands[:-1], setup_commands[-1] + "; ".join(input_commands)]

    result = subprocess.run(all_commands, cwd=cwd)
    result.check_returncode()


def collect_requirements(
    func: Callable[P, tuple[RawFilesDict, RequirementsBase]]
) -> Callable[P, tuple[RequirementsDict, RequirementsBase]]:
    @wraps(func)
    def wrapper(*args: P.args, **kwargs: P.kwargs) -> tuple[RequirementsDict, RequirementsBase]:
        files_dict, requirements_base = func(*args, **kwargs)
        requirements_dict = {filename: "\n".join(requirements) for filename, requirements in files_dict.items()}
        return requirements_dict, requirements_base

    return wrapper


def write_files(files: RequirementsDict, dir: Path) -> None:
    for filename, contents in files.items():
        (dir / filename).write_text(contents + "\n")
