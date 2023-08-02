# Changelog

## [v1.1.0](https://github.com/SallingGroup-AI-and-ML/venv-cli/releases/tag/v1.1.0) (2023-08-02)

### Internal changes

* Added functionality to `venv lock`: Since `pip freeze` (which `venv lock` is using under the hood) does not output the `auth`-part of VCS URLs, `venv lock` now includes a fix that tries to read them from a reference `requirements`-file, but **only if they are specified as environment variables** so as not to accidentally expose secrets in version-controlled `.lock`-files.

For more info on this, see `venv lock --help`.

## [v1.0.2](https://github.com/SallingGroup-AI-and-ML/venv-cli/releases/tag/v1.0.2) (2023-08-02)

* Fixed test that checks the version number follows the required pattern.

## [v1.0.1](https://github.com/SallingGroup-AI-and-ML/venv-cli/releases/tag/v1.0.1) (2023-08-02)

* Added support for `zsh` shell.
* Added `CHANGELOG.md`.

## [1.0.0](https://github.com/SallingGroup-AI-and-ML/venv-cli/releases/tag/v1.0.0) (2023-07-13)

This is the first release of the `venv-cli` tool.
