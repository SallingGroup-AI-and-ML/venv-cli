import itertools

from pytest_cases import parametrize

from tests.helpers import collect_requirements
from tests.types import PackageName, PackageSpec, RawFilesDict, RequirementsStem


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


class CasesVenvAddPackagesToRequirements:
    @parametrize("version", ["", "==2.0.7", " == 2.0.7"])
    @collect_requirements
    def case_empty(
        self, version: str
    ) -> tuple[RawFilesDict, tuple[RequirementsStem, list[tuple[PackageName, PackageSpec]]]]:
        requirements_txt: list[str] = []

        name_spec: list[tuple[PackageName, PackageSpec]] = [
            ("python-json-logger", f"python-json-logger{version}"),
        ]

        files = {"requirements.txt": requirements_txt}
        return files, (RequirementsStem.requirements, name_spec)

    @parametrize("version", ["", "==2.0.7", " == 2.0.7"])
    @collect_requirements
    def case_has_one_add_one(
        self, version: str
    ) -> tuple[RawFilesDict, tuple[RequirementsStem, list[tuple[PackageName, PackageSpec]]]]:
        requirements_txt = [
            "numpy==1.26.0",
        ]

        name_spec: list[tuple[PackageName, PackageSpec]] = [
            ("python-json-logger", f"python-json-logger{version}"),
        ]

        files = {"requirements.txt": requirements_txt}
        return files, (RequirementsStem.requirements, name_spec)

    @parametrize("version", ["", "==2.0.7", " == 2.0.7"])
    @collect_requirements
    def case_has_several_add_one(
        self, version: str
    ) -> tuple[RawFilesDict, tuple[RequirementsStem, list[tuple[PackageName, PackageSpec]]]]:
        core_txt = [
            "wheel",
        ]

        requirements_txt = [
            "-r core.txt",
            "numpy==1.26.0",
            "requests",
        ]

        name_spec: list[tuple[PackageName, PackageSpec]] = [
            ("python-json-logger", f"python-json-logger{version}"),
        ]

        files = {"core.txt": core_txt, "requirements.txt": requirements_txt}
        return files, (RequirementsStem.requirements, name_spec)

    @parametrize(
        "versions",
        itertools.product(["", "==2.2.1", " == 2.2.1"], ["", "==2.0.7", " == 2.0.7"]),
    )
    @collect_requirements
    def case_has_several_add_several(
        self, versions: tuple[str, str]
    ) -> tuple[RawFilesDict, tuple[RequirementsStem, list[tuple[PackageName, PackageSpec]]]]:
        core_txt = [
            "wheel",
        ]

        requirements_txt = [
            "-r core.txt",
            "numpy==1.26.0",
            "requests",
        ]

        name_spec: list[tuple[PackageName, PackageSpec]] = [
            ("urllib3", f"urllib3{versions[0]}"),
            ("python-json-logger", f"python-json-logger{versions[1]}"),
        ]

        files = {"core.txt": core_txt, "requirements.txt": requirements_txt}
        return files, (RequirementsStem.requirements, name_spec)
