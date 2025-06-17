# Changelog

## Unreleased
* The project is now following the [Github Flow](https://docs.github.com/en/get-started/using-github/github-flow) branching model. The `main` branch is now the default branch, and the `develop` branch has been removed. Future development should create a new branch directly from `main`, and when done, creating a pull request back into `main`. Releases should be tagged directly on `main` as well.

## [v2.0.0](https://github.com/SallingGroup-AI-and-ML/venv-cli/releases/tag/v2.0.0) (2024-03-06)

### Breaking changes
* `venv install` can now be used to install individual packages: `venv install <package>`. [#37](https://github.com/SallingGroup-AI-and-ML/venv-cli/pull/37)

  To enable this feature, installing from a requirements file now requires the use of the new `-r | --requirement` flags: `venv install -r requirements.txt`. Packages installed using `venv install <package>` are first added to the requirements file before reinstalling the entire environment to ensure reproducibility. To uninstall packages, use the new `venv uninstall` subcommand, e.g. `venv uninstall <package>`.
* `venv sync` has been removed. Use `venv install -r <requirements>.lock` instead. [#17](https://github.com/SallingGroup-AI-and-ML/venv-cli/pull/17)

### Major changes
* Added `venv uninstall` subcommand to complement the new functionality of `venv install <package>`. [#37](https://github.com/SallingGroup-AI-and-ML/venv-cli/pull/37)

  Running `venv uninstall <package>` will first remove the package from `requirements.txt`, then use `venv install -r requirements.txt` to reinstall the environment without `<package>`.

  This process ensures that there are no "orphaned dependencies" left in the environment after uninstalling, unlike when using `pip uninstall <package>`.
* Loosened the file name requirements for `requirements` files. Requirements files can now be any valid file name with the extension `.txt` (`.lock` for lock files). [#35](https://github.com/SallingGroup-AI-and-ML/venv-cli/pull/35)

### Minor changes
* The `install.sh` script now supports specifying for which shell to install `venv-cli`, e.g. `./install.sh zsh`. [#29](https://github.com/SallingGroup-AI-and-ML/venv-cli/pull/29)
* Updated virtual environment activation instructions in `README.md` and when running `venv activate -h` [#37](https://github.com/SallingGroup-AI-and-ML/venv-cli/pull/37)
* Refactored bash completion script to enable better handling of arguments for subcommands. [8ac4daf](https://github.com/SallingGroup-AI-and-ML/venv-cli/pull/32/commits/8ac4daf89314f0ac2c1daf56bee9f4ac489f5004)

### Bug fixes
* Running the uninstall script now correctly removes the sourcing line from the user's `rc`-file. [#29](https://github.com/SallingGroup-AI-and-ML/venv-cli/pull/29)
* Running the installation script now adds the sourcing line to the user's `rc`-file only if it is not there already. [#29](https://github.com/SallingGroup-AI-and-ML/venv-cli/pull/29)
* Running `venv <subcommand>` now correctly returns the exit code from that subcommand. [8b7a54d](https://github.com/SallingGroup-AI-and-ML/venv-cli/commit/8b7a54db77e075760847dba8c12489e7fc4dbd4d)
* Removed a unit test that was failing sporadically when running tests multiprocessed using `pytest-xdist`. [30c501c](https://github.com/SallingGroup-AI-and-ML/venv-cli/commit/30c501ce1ef43d151ceb22718de80dc9ea9c30ac)

### Internal changes
* Added several new test cases to cover loosened requirements file name check. [#35](https://github.com/SallingGroup-AI-and-ML/venv-cli/pull/35)
* Removed unused test files. [8be87d9](https://github.com/SallingGroup-AI-and-ML/venv-cli/commit/8be87d95a75f5b532eaf1fd062796674ce7a764c)
* Updated test cases for `venv clear` and `venv lock` that use the `venv install` command. [6985681](https://github.com/SallingGroup-AI-and-ML/venv-cli/pull/32/commits/6985681a3b3ac8ae783406e1b76401b7075ea260)
* Unit test jobs for different shells in CI/CD now run in parallel, speeding up runtime of the CI/CD pipeline. [d2d9ec3](https://github.com/SallingGroup-AI-and-ML/venv-cli/pull/32/commits/d2d9ec3c16169bb87460165a42cbce8284b4efdc)

## [v1.5.1](https://github.com/SallingGroup-AI-and-ML/venv-cli/releases/tag/v1.5.1) (2024-01-10)

### Minor changes
* `venv install` now fails early and with a more descriptve error message when run outside of a virtual environment. [#31](https://github.com/SallingGroup-AI-and-ML/venv-cli/pull/31)

### Bug fixes
* `venv clear` is now able to clear virtual environments that contain editable installs. [#31](https://github.com/SallingGroup-AI-and-ML/venv-cli/pull/31)

## [v1.5.0](https://github.com/SallingGroup-AI-and-ML/venv-cli/releases/tag/v1.5.0) (2024-01-04)

### Major changes
* Added `venv delete` command. [#25](https://github.com/SallingGroup-AI-and-ML/venv-cli/pull/25)

  Running `venv delete` completely removes the virtual environment located in the current folder.

### Minor changes
* Added `-s` alias for `--skip-lock` when running `venv install`. [#24](https://github.com/SallingGroup-AI-and-ML/venv-cli/pull/24)

### Internal changes
* The `run_command` test helper function can now pass through inputs to the command that is being run.

## [v1.4.1](https://github.com/SallingGroup-AI-and-ML/venv-cli/releases/tag/v1.4.1) (2023-10-30)

### Bugfixes
* Fixed `venv lock` failing to lock when called as part of `venv install`. [#21](https://github.com/SallingGroup-AI-and-ML/venv-cli/pull/21)

## [v1.4.0](https://github.com/SallingGroup-AI-and-ML/venv-cli/releases/tag/v1.4.0) (2023-10-30)

### Minor changes
* `venv install` now runs `venv clear` before installation. This ensures that the enrivonment doesn't end up with orphaned packages after making changes to `requirements.txt`. [#9](https://github.com/SallingGroup-AI-and-ML/venv-cli/issues/9)

## Minor changes
* `venv sync` command marked as deprecated with removal planned for `v2.0`. Use `venv install <requirements>.lock` instead. [#14](https://github.com/SallingGroup-AI-and-ML/venv-cli/pull/14)

## [v1.3.0](https://github.com/SallingGroup-AI-and-ML/venv-cli/releases/tag/v1.3.0) (2023-10-30)

## Major changes
* `venv lock` no longer tries to fill in credentials for packages installed via VCS. This behavior was undocumented and difficult to maintain and ultimately tried to alleviate a shortcoming of the way `pip` handles these credentials. [#11](https://github.com/SallingGroup-AI-and-ML/venv-cli/pull/11)
For users who have credentials as part of URLs in their `requirements.txt` files, there are other ways to handle credentials, e.g. filling them in `requirements.lock` manually, using a `.netrc` file to store the credetials or using a keyring. See https://pip.pypa.io/en/stable/topics/authentication/ for more info.

### Minor changes
* `venv create` now prints the full python version used for creating the environment. [bb62c21](https://github.com/SallingGroup-AI-and-ML/venv-cli/commit/bb62c216cbad2fcec06bfb1cde8b875dbfc237d3)

### Internal changes
* Added `pytest-cases` to development dependencies.

## [v1.2.0](https://github.com/SallingGroup-AI-and-ML/venv-cli/releases/tag/v1.2.0) (2023-08-04)

From this release forward, this project follows the `Git Flow` branching model. To reflect this, the default development branch have been renamed `develop`, and the `main` branch is now only for tagged releases.
To read more about Git Flow, see (https://nvie.com/posts/a-successful-git-branching-model/). Also see [README](https://github.com/SallingGroup-AI-and-ML/venv-cli/blob/v1.2.0/README.md#git-flow) for branch naming conventions.

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
