from enum import Enum
from pathlib import Path
from typing import ParamSpec

P = ParamSpec("P")
RawFilesDict = dict[str, list[str]]
RequirementsDict = dict[str, str]
RequirementFiles = dict[str, Path]


class RequirementsStem(str, Enum):
    requirements = "requirements"
    dev_requirements = "dev-requirements"
    all = "all"
