import os
import subprocess
import sys
from functools import wraps
from pathlib import Path
from typing import Callable, Optional, TypeVar

from tests.types import P, RawFilesDict, RequirementsDict, RequirementsStem

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


def run_command(
    commands: str | list[str],
    cwd: Path = Path.cwd(),
    activated: bool = False,
    command_input: Optional[str] = None,
) -> None:
    """Run a command in a subprocess, optionally activating the virtual environment first

    Args:
        commands: The command(s) to run.
        cwd: The directory to run the command in. Defaults to the current working directory.
        activated: Whether to activate the virtual environment before running the command.
        command_input: The input to pass to the command. Defaults to None.

    Raises:
        subprocess.CalledProcessError: If the command returns a non-zero exit code.
    """
    input_commands = [commands] if isinstance(commands, str) else commands

    setup_commands = _command_setup(venv_cli_path=_venv_cli_path, activate=activated)
    all_commands = [*setup_commands[:-1], setup_commands[-1] + "; ".join(input_commands)]

    result = subprocess.run(all_commands, cwd=cwd, input=command_input, text=True)
    result.check_returncode()


R = TypeVar("R")


def collect_requirements(func: Callable[P, tuple[RawFilesDict, R]]) -> Callable[P, tuple[RequirementsDict, R]]:
    @wraps(func)
    def wrapper(*args: P.args, **kwargs: P.kwargs) -> tuple[RequirementsDict, R]:
        files_dict, other = func(*args, **kwargs)
        requirements_dict = {filename: "\n".join(requirements) for filename, requirements in files_dict.items()}
        return requirements_dict, other

    return wrapper


def write_files(files: RequirementsDict, dir: Path) -> None:
    for filename, contents in files.items():
        (dir / filename).write_text(contents + "\n")
