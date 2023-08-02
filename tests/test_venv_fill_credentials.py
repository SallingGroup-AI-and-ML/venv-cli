# from collections import NamedTuple
from pathlib import Path
from textwrap import dedent
from typing import NamedTuple

import pytest

from tests.helpers import run_command


class _TestCase(NamedTuple):
    requirements: str
    locked: str
    expected: str


@pytest.mark.order(after="test_venv_install.py::test_venv_install")
@pytest.mark.parametrize(
    "test_case",
    [
        _TestCase(
            requirements="""
            numpy
            """,
            locked=(
                _locked := """
            numpy==1.25.1
            """
            ),
            expected=_locked,
        ),
        _TestCase(
            requirements="""
            asdf-lib @ git+https://github.com/someguy/asdf-lib
            """,
            locked=(
                _locked := """
            asdf-lib @ git+https://github.com/someguy/asdf-lib@commithash0
            """
            ),
            expected=_locked,
        ),
        _TestCase(
            requirements="""
            asdf-lib @ git+https://${TEST_TOKEN}@github.com/someguy/asdf-lib
            """,
            locked="""
            asdf-lib @ git+https://github.com/someguy/asdf-lib@commithash0
            """,
            expected="""
            asdf-lib @ git+https://${TEST_TOKEN}@github.com/someguy/asdf-lib@commithash0
            """,
        ),
        _TestCase(
            requirements="""
            randomlib @ git+https://${TEST_USER}:${TEST_PASS}@github.com/user1/randomlib
            """,
            locked="""
            randomlib @ git+https://github.com/user1/randomlib@commithash1
            """,
            expected="""
            randomlib @ git+https://${TEST_USER}:${TEST_PASS}@github.com/user1/randomlib@commithash1
            """,
        ),
        _TestCase(
            requirements="""
            numpy==1.25.1
            asdf-lib @ git+https://github.com/someguy/asdf-lib
            randomlib @ git+https://github.com/user1/randomlib
            other-randomlib @ git+https://github.com/user2/other-randomlib
            randomlib-new @ git+https://github.com/user3/randomlib-new
            """,
            locked=(
                _locked := """
            numpy==1.25.1
            asdf-lib @ git+https://github.com/someguy/asdf-lib@commithash0
            randomlib @ git+https://github.com/user1/randomlib@commithash1
            other-randomlib @ git+https://github.com/user2/other-randomlib@commithash2
            randomlib-new @ git+https://github.com/user3/randomlib-new@commithash3
            """
            ),
            expected=_locked,
        ),
        _TestCase(
            requirements="""
            numpy==1.25.1
            asdf-lib @ git+https://${TEST_TOKEN}@github.com/someguy/asdf-lib
            randomlib @ git+https://${TEST_USER}:${TEST_PASS}@github.com/user1/randomlib
            other-randomlib @ git+https://github.com/user2/other-randomlib
            randomlib-new @ git+https://github.com/user3/randomlib-new
            """,
            locked="""
            numpy==1.25.1
            asdf-lib @ git+https://github.com/someguy/asdf-lib@commithash0
            randomlib @ git+https://github.com/user1/randomlib@commithash1
            other-randomlib @ git+https://github.com/user2/other-randomlib@commithash2
            randomlib-new @ git+https://github.com/user3/randomlib-new@commithash3
            """,
            expected="""
            numpy==1.25.1
            asdf-lib @ git+https://${TEST_TOKEN}@github.com/someguy/asdf-lib@commithash0
            randomlib @ git+https://${TEST_USER}:${TEST_PASS}@github.com/user1/randomlib@commithash1
            other-randomlib @ git+https://github.com/user2/other-randomlib@commithash2
            randomlib-new @ git+https://github.com/user3/randomlib-new@commithash3
            """,
        ),
    ],
)
def test_venv_fill_credentials(test_case: _TestCase, tmp_path: Path):
    """Checks that venv::_fill_credentials can read env var credentials
    from requirements file and fill them into lock file"""
    tmp_path.mkdir(parents=True, exist_ok=True)

    requirements_file = tmp_path / "requirements.txt"
    with requirements_file.open("w") as file:
        file.write(dedent(test_case.requirements).lstrip())

    lock_file = tmp_path / "requirements.lock"
    with lock_file.open("w") as file:
        file.write(dedent(test_case.locked).lstrip())

    run_command(f"venv::_fill_credentials {requirements_file} {lock_file}", activated=False, cwd=tmp_path)

    actual = lock_file.read_text()
    assert actual == dedent(test_case.expected).lstrip()
