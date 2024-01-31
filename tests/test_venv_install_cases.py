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


class CasesVenvInstallWithLock:
    @collect_requirements
    def case_pypi(self) -> tuple[RawFilesDict, RequirementsStem]:
        requirements_txt = [
            "python-json-logger==2.0.7",
        ]

        files = {"requirements.txt": requirements_txt}
        return files, RequirementsStem.requirements
