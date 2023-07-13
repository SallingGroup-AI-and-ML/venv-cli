from pathlib import Path
from shutil import copy2

import pytest

from tests.helpers import Files


@pytest.fixture
def venv_dir(tmp_path: Path) -> Files:
    src = Path.cwd() / "tests" / "files"
    dst = tmp_path
    reqs = Path("requirements")
    dev_reqs = Path("dev-requirements")

    files = Files(
        {
            "base": dst,
            "requirements.txt": copy2(
                src=src / reqs.with_suffix(".txt"),
                dst=dst / reqs.with_suffix(".txt"),
            ),
            "requirements.lock": copy2(
                src=src / reqs.with_suffix(".lock"),
                dst=dst / reqs.with_suffix(".lock"),
            ),
            "dev-requirements.txt": copy2(
                src=src / dev_reqs.with_suffix(".txt"),
                dst=dst / dev_reqs.with_suffix(".txt"),
            ),
            "dev-requirements.lock": copy2(
                src=src / dev_reqs.with_suffix(".lock"),
                dst=dst / dev_reqs.with_suffix(".lock"),
            ),
        }
    )
    return files
