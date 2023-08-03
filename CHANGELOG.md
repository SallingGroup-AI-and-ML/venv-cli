# Changelog

## Unreleased

From this release forward, this project follows the `Git Flow` branching model. To reflect this, the default development branch have been renamed `develop`, and the `main` branch is now only for tagged releases.
To read more about Git Flow, see (https://nvie.com/posts/a-successful-git-branching-model/). Also see [README](https://github.com/SallingGroup-AI-and-ML/venv-cli/blob/develop/README.md#git-flow) for branch naming conventions.

* Changed github test workflow to reflect new branch naming conventions.
* Added better, context-based bash completions.

## [v1.1.0](https://github.com/SallingGroup-AI-and-ML/venv-cli/releases/tag/v1.1.0) (2023-08-02)

### New install script
This release adds an `install.sh` script for easier installation of `venv-cli`. Now it can be installed by simply running
```console
$ bash install.sh
```

For more information on installing and uninstalling, see the updated [README](https://github.com/SallingGroup-AI-and-ML/venv-cli/blob/v1.1.0/README.md)

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
