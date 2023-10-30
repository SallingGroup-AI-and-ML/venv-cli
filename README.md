[![Linting and tests](https://github.com/SallingGroup-AI-and-ML/venv-cli/actions/workflows/run_tests.yml/badge.svg)](https://github.com/SallingGroup-AI-and-ML/venv-cli/actions/workflows/run_tests.yml)

# venv-cli - A CLI tool to create and manage virtual python environments.

## Overview
`venv-cli` is a CLI tool to help create and manage virtual python environments.
It uses `pip` and `python -m venv` underneath, and so only requires core python. This alleviates the bootstrapping problem of needing to install a python package using your system `python` and `pip` before you are able to create virtual environments.

You also don't need `conda`, `pyenv`, `pythonz` etc. to manage your python versions. Just make sure the correct version of python is installed on your system, then reference that specific version when creating the virtual environment, and everything just works. No shims, no path hacks, just the official `python` build.

## Installation

Clone this repository, then run the `install.sh` script from your favourite shell:
```console
$ bash install.sh
```
This will install the `venv` source file, along with an uninstall script, in `/usr/local/share/venv/`, and add a line in the appropriate shell `rc`-file (e.g. `~/.bashrc`) sourcing the `venv` source script.

This makes the `venv` command avaiable in your terminal. To check if it works, restart the terminal and run
```console
$ venv --version
venv-cli 1.0.0
```

The install script also adds command completions for the invoked shell.

# Uninstall
To uninstall `venv` and remove all files, run the uninstall script at `/usr/local/share/venv/`:
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
$ sudo apt install python<version>-venv
```
e.g.
```console
$ sudo apt install python3.10-venv
```

The `-venv` part is necessary to be able to use this system python to create virtual environments.

## Activating and deactivating the virtual environment
To activate the virtual environment, from the folder containing `.venv` run
```console
$ venv activate
```

To deactivate it again, run
```console
$ venv deactivate
```

## Install packages/requirements
The proper way to install packages in the virtual environment is to add them to a `requirements.txt` file and then install from that:

```console
$ echo "pandas ~= 1.5" >> requirements.txt

$ venv install requirements.txt

Installing requirements from requirements.txt
Collecting pandas~=1.5
  Using cached pandas-1.5.3-cp310-cp310-manylinux_2_17_x86_64.manylinux2014_x86_64.whl (12.1 MB)
Collecting python-dateutil>=2.8.1
  Using cached python_dateutil-2.8.2-py2.py3-none-any.whl (247 kB)
Collecting numpy>=1.21.0
  Using cached numpy-1.25.1-cp310-cp310-manylinux_2_17_x86_64.manylinux2014_x86_64.whl (17.6 MB)
Collecting pytz>=2020.1
  Using cached pytz-2023.3-py2.py3-none-any.whl (502 kB)
Collecting six>=1.5
  Using cached six-1.16.0-py2.py3-none-any.whl (11 kB)
Installing collected packages: pytz, six, numpy, python-dateutil, pandas
Successfully installed numpy-1.25.1 pandas-1.5.3 python-dateutil-2.8.2 pytz-2023.3 six-1.16.0
```

In fact, if you don't specify the file name, `venv` will assume that you want to install from `requirements.txt`, so
```console
$ venv install

$ venv install requirements.txt
```
are equivalent.

The installed packages are then _locked_ into the corresponding `.lock`-file, e.g. running `venv install dev-requirements.txt` will lock those installed packages into `dev-requirements.lock`[^1].

Installing packages this way makes sure that they are tracked, since installing them with `pip install` will keep no record of which packages have been installed in the environment, making it difficult to reproduce later on.

### Development packages
If you have both production and development package requirements, keep them in separate requirements-files, e.g. `requirements.txt` for production and `dev-requirements.txt` for development. An example of these could be:
```bash
# requirements.txt
numpy
pandas ~= 1.5


# dev-requirements.txt
-r requirements.txt
jupyter
matplotlib
```

The `-r requirements.txt` will make sure that installing development requirements also install production requirements.

## Reproducing environment
To install a reproducible environment, you need to install from a `.lock`-file, since those have all versions of all requirements locked[^1]. From a clean environment (no packages installed yet), run
```console
$ venv install requirements.lock
```

If you don't have a clean environment, but still want to recreate the environment as it was when the requirements were locked, you can run
```console
$ venv sync requirements.lock
```

This will first remove all installed packages, then run `venv install requirements.lock`.

**NOTE: Since this command is meant to create a reproducable environment, you cannot `sync` to a `.txt` file; it has to be a `.lock` file.**

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

## Contributing

As this is meant to be a lightweight tool providing simple, QoL improvements to working with `pip` and `python -m venv`, we will not be adding a lot of big, additional features.

That said, pull requests are welcome. For bigger changes, please open an issue first to discuss what you would like to change.

To contribute, clone the repo and create a branch, create a virtual environment (preferably using `venv-cli`) and install `dev-requirements.txt`. When you are done with your changes, run the test suite with
```console
$ pytest .
```
then create a pull request for the `develop` branch.

Every subcommand has its own test file `tests/test_venv_<command>.py` Please make sure to add/update tests as appropriate.

### Git Flow
This project follows the [Git Flow](https://nvie.com/posts/a-successful-git-branching-model/) branching model. The default development branch is accordingly named `develop`, and the branch `main` is reserved for tagged releases and hotfixes. Other branches should be named according to their purpose:
```
feature/<branch name>
bugfix/<branch name>
release/<branch name>
hotfix/<branch name>
support/<branch name>
```

Releases are made by creating a branch `release/vX.X.X` from `develop`, where `X.X.X` represents the release version number, following [SemVer](https://semver.org/). This freezes the version number of **this release**, and no more features from `develop` should be merged into this release (only `bugfix/`). When the `release/` branch is ready for release, merge it into `main` and tag the commit with the release version, then merge the `release/` branch back into `develop` (resolving any merge conflicts) to get the bugfixes included there as well.

## License

[MIT](https://choosealicense.com/licenses/mit/)

[^1]: A current limitation of using `pip freeze` under the hood is that installing packages from a version control system (VCS) URL that requires authentication, e.g. `private_package @ git+https://USERNAME:PASSWORD@github.com/my-user/private-package`, the authentication is not locked (see https://github.com/pypa/pip/issues/12365).
These credentials can either be inserted manually into the generated `.lock`-file, or the credentials can instead be stored in a `.netrc` file, which `pip install` will then reference when running `pip install`: https://pip.pypa.io/en/stable/topics/authentication/#netrc-support
