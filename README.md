[![Linting and tests](https://github.com/SallingGroup-AI-and-ML/venv-cli/actions/workflows/run_tests.yml/badge.svg)](https://github.com/SallingGroup-AI-and-ML/venv-cli/actions/workflows/run_tests.yml)
![GitHub License](https://img.shields.io/github/license/SallingGroup-AI-and-ML/venv-cli)

# venv-cli - A CLI tool to create and manage virtual python environments.

## Overview
`venv-cli` is a CLI tool to help create and manage virtual python environments.
It is built on `pip` and `python -m venv`, and so only requires packages that are already part of the core python installation; no third-party python packages required. This alleviates the bootstrapping problem of needing to install a python package using your system `python` and `pip` before you are able to create virtual environments.

You also don't need `conda`, `pyenv`, `pythonz` etc. to manage your python versions. Just make sure the correct version of python is installed on your system, then reference that specific version when creating the virtual environment, and everything just works. No shims, no path hacks, just the official `python` build.

## Installation

Clone this repository, then run the `install.sh` script:
```console
$ ./install.sh
```
This will install the `venv` source file, along with an uninstall script, in `/usr/local/share/venv/`, and add a line in the appropriate shell `rc`-file (e.g. `~/.bashrc`) sourcing the `venv` source script.

The default shell is `bash`. To install for a different shell, specify the shell name, e.g.
```console
$ ./install.sh zsh
```

The installation makes the `venv` command available in your terminal. To check if it works, restart the terminal and run
```console
$ venv --version
venv-cli 1.0.0
```

# Uninstall
To uninstall `venv` and remove all files, run the uninstall script placed at `/usr/local/share/venv/`:
```console
$ bash /usr/local/share/venv/uninstall.sh
```
The script should be run by the user that ran the install script to correctly remove the sourcing lines from the `rc`-file of that user. However, since it also cleans up the files in `/usr/share/local/venv/`, it will ask for `sudo` access.

## Usage

To see the help menu, along with a list of available commands, run `venv -h/--help`.

**In the following sections it is assumed that the working directory is the folder `~/project`.**
### Create virtual environment
To create a virtual environment, use the command
```console
$ venv create <python-version>
```
e.g.
```console
$ venv create 3.9
```

This creates a virtual environment using the `python3.9` executable on `$PATH`. The name of the virtual environment will be the name of the current folder (in this case, `project` ), unless you specify a name when creating the environment:

```console
$ venv create 3.9 venv-name
```

If you don't have the specific version of python installed yet, you can get it by running
```console
$ sudo apt install python<version>
```
e.g.
```console
$ sudo apt install python3.10
```
(or in the case of Debian-based distributions, like Ubuntu, `sudo apt install python3.10-venv`. The `-venv` part is necessary to be able to use the system python to create virtual environments.)

## Activating and deactivating the virtual environment
To activate the virtual environment, place yourself _in the folder containing_ the `.venv` folder, then run
```console
$ venv activate
```

To deactivate it again, run
```console
$ venv deactivate
```

## Install/uninstall packages and requirements
To install a single package, simply run
```console
$ venv install <package>
```

This will install the `<package>` in the current environment. However, it does more than that.
A main design philosophy of `venv-cli` is to always keep the current environment in a reproducible state. For this reason, `venv-cli` aims to always keep a requirements file up to date with that state.

This means that when running `venv install <package>`, the package is first added (or appended) to a `requirements.txt` file in the current folder, and then the command `venv install -r requirements.txt` is run, which clears the entire environment and reinstalls it from scratch using the requirements specified in `requirements.txt`.

Unlike `pip install <package>`, which leaves no trace, this ensures that the `requirements.txt` keeps a record of the packages that have been manually installed.

In the same spirit, `venv uninstall <package>` first removes the package from `requirements.txt`, then runs `venv install -r requirements.txt` to reinstall the environment from scratch. Unlike `pip uninstall <package>`, this ensures that the uninstall does not leave any "orphaned" packages in the current environment (packages that were installed as secondary dependencies, but are no longer needed since the primary dependency has been uninstalled).

### Requirements files
To specify a different requirements file to install to/uninstall from, use `-r <requirements>` :
```console
$ venv install numpy 'pandas >= 2.0' -r core.txt
```
This will add `numpy` and `pandas >= 2.0` as requirements in `core.txt`, then install from that file. Similarly,
```console
$ venv uninstall pandas -r core.txt
```
will remove the `pandas >= 2.0` requirement from `core.txt` again, then reinstall the environment using the updated `core.txt`.

### Lock files
When installing or uninstalling packages, the resulting environment is _locked_ into a corresponding `.lock`-file, e.g. running `venv install -r requirements.txt` will lock the installed packages into `requirements.lock`[^1].

This file is useful if a reproducible install is needed, e.g. when deploying a project to a different machine, or when running a colleagues project. Where `requrements.txt` is used to specify the packages and version your project _needs_ (and nothing more), installing from `requirements.lock` makes sure that you get the exact version of every package.

### Additional requirements
If you have both production and development package requirements, keep them in separate requirements-files, e.g. `requirements.txt` for production requirements and `test.txt` for requirements needed when running tests. An example of these could be:
```bash
# requirements.txt
numpy
pandas ~= 1.5


# test.txt
-r requirements.txt
pytest
pytest-cov
```

You can then use either
```console
$ venv install -r requirements.txt
```

To install production requirements only, or
```console
$ venv install -r test.txt
```

to install both production and test requirements. The `-r requirements.txt` in `test.txt` is what makes sure that installing test requirements also installs the requirements from `requirements.txt`.

## Clearing the environment
If you want to manually clear the environment, you can run
```console
$ venv clear
```

This will uninstall all installed packages from the environment. This is useful if you have installed development packages, and then need to get back to a production environment, e.g.

```console
$ venv install dev-requirements.txt

# Later
$ venv clear
$ venv install requirements.txt
```

## Deleting the environment
To completely delete the virtual environment and everything in it, run
```console
$ venv delete
```

(this will not delete any requirement or .lock-files). This will ask for confirmation before deleting the virtual environment. To give immediate confirmation, pass the `-y` flag:
```console
$ venv delete -y
```

## Contributing
Before creating a pull request, please open an issue first to discuss what you would like to change.

To contribute, clone the repo and create a branch, create a virtual environment and install `dev-requirements.txt`. When you are done with your changes, run the test suite with
```console
$ pytest .
```
then create a pull request for the `main` branch.

Every (public) subcommand has its own test file `tests/test_venv_<command>.py` Please make sure to add/update tests as appropriate.

### Branches
When creating a new branch, please prefix them with one of the following:

```
feature/<branch name>
bugfix/<branch name>
release/<branch name>
hotfix/<branch name>
support/<branch name>
```

### Releases

When making a release, e.g. `v1.2.3`, first update the `_version` number in `venv.sh` to `"v1.2.3"`, then add a new header in the `CHANGELOG.md` file, directly under the `## Unreleased` header, with the version number and date, e.g.

```markdown
## [v1.2.3](https://github.com/SallingGroup-AI-and-ML/venv-cli/releases/tag/v1.2.3) (2025-05-30)
```

The release tag should follow the format `v<major>.<minor>.<patch>`, e.g. `v1.2.3`.

Then commit the changes, push to `main`, and create a new release on GitHub with the same version number as the tag.

## License

[MIT](https://choosealicense.com/licenses/mit/)

[^1]: A current limitation of using `pip freeze` under the hood is that installing packages from a version control system (VCS) URL that requires authentication, e.g. `private_package @ git+https://USERNAME:PASSWORD@github.com/my-user/private-package`, the authentication is not locked (see https://github.com/pypa/pip/issues/12365).
These credentials can either be inserted manually into the generated `.lock`-file, or the credentials can instead be stored in a `.netrc` file, which `pip install` will then reference when running `pip install`: https://pip.pypa.io/en/stable/topics/authentication/#netrc-support
