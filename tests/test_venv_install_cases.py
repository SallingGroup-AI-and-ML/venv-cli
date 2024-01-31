from tests.helpers import collect_requirements
from tests.types import RawFilesDict, RequirementsStem


class CasesVenvInstallRequirementstxt:
    @collect_requirements
    def case_pypi(self) -> tuple[RawFilesDict, RequirementsStem]:
        requirements_txt = [
            "python-json-logger==2.0.7",
        ]

        files = {"requirements.txt": requirements_txt}
        return files, RequirementsStem.requirements

    @collect_requirements
    def case_git(self) -> tuple[RawFilesDict, RequirementsStem]:
        requirements_txt = [
            "python-json-logger @ git+https://github.com/madzak/python-json-logger@v2.0.7",
        ]

        files = {"requirements.txt": requirements_txt}
        return files, RequirementsStem.requirements

    @collect_requirements
    def case_pypi_dev(self) -> tuple[RawFilesDict, RequirementsStem]:
        requirements_txt = [
            "python-json-logger==2.0.7",
        ]

        dev_requirements_txt = [
            "-r requirements.txt",
            "numpy==1.26.0",
        ]

        files = {
            "requirements.txt": requirements_txt,
            "dev-requirements.txt": dev_requirements_txt,
        }
        return files, RequirementsStem.dev_requirements

    @collect_requirements
    def case_git_dev(self) -> tuple[RawFilesDict, RequirementsStem]:
        requirements_txt = [
            "python-json-logger @ git+https://github.com/madzak/python-json-logger@v2.0.7",
        ]

        dev_requirements_txt = [
            "-r requirements.txt",
            "numpy==1.26.0",
        ]

        files = {
            "requirements.txt": requirements_txt,
            "dev-requirements.txt": dev_requirements_txt,
        }
        return files, RequirementsStem.dev_requirements

    @collect_requirements
    def case_pypi_several_nested(self) -> tuple[RawFilesDict, RequirementsStem]:
        core_txt = [
            "python-json-logger==2.0.7",
        ]

        test_txt = [
            "pytest",
        ]

        lint_txt = [
            "black",
        ]

        all_txt = [
            "-r core.txt",
            "-r test.txt",
            "-r lint.txt",
            "numpy==1.26.0",
        ]

        files = {
            "core.txt": core_txt,
            "test.txt": test_txt,
            "lint.txt": lint_txt,
            "all.txt": all_txt,
        }
        return files, RequirementsStem.all


class CasesVenvInstallWithLock:
    @collect_requirements
    def case_pypi(self) -> tuple[RawFilesDict, RequirementsStem]:
        requirements_txt = [
            "python-json-logger==2.0.7",
        ]

        files = {"requirements.txt": requirements_txt}
        return files, RequirementsStem.requirements
