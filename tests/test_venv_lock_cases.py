from tests.helpers import collect_requirements
from tests.types import RawFilesDict, RequirementsBase


class CasesVenvLock:
    @collect_requirements
    def case_requirements(self) -> tuple[RawFilesDict, RequirementsBase]:
        requirements_txt = [
            "python-json-logger==2.0.7",
            "resolvelib @ git+https://github.com/sarugaku/resolvelib@1.0.1",
        ]
        requirements_lock = [
            "python-json-logger==2.0.7",
            "resolvelib @ git+https://github.com/sarugaku/resolvelib@c9ef371ad96e698bf3e0bb09acc682bd43e39bd7",
        ]

        files = {
            "requirements.txt": requirements_txt,
            "requirements.lock": requirements_lock,
        }
        return files, RequirementsBase.requirements

    @collect_requirements
    def case_dev_requirements(self) -> tuple[RawFilesDict, RequirementsBase]:
        requirements_txt = [
            "python-json-logger==2.0.7",
        ]

        dev_requirements_txt = [
            "-r requirements.txt",
            "numpy==1.26.0",
        ]

        dev_requirements_lock = [
            "numpy==1.26.0",
            "python-json-logger==2.0.7",
        ]

        files = {
            "requirements.txt": requirements_txt,
            "dev-requirements.txt": dev_requirements_txt,
            "dev-requirements.lock": dev_requirements_lock,
        }
        return files, RequirementsBase.dev_requirements
