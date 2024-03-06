#!/bin/bash

_success=0
_fail=1

_normal="\033[00m"
_green="\033[32m"
_yellow="\033[01;33m"
_red="\033[31m"

# Version number has to follow pattern "^v\d+\.\d+\.\d+.*$"
_version="v2.0.0"

# Valid VCS URL environment variable pattern
# https://peps.python.org/pep-0610/#specification
_env_var_auth_pattern='\${[-_A-Za-z0-9]+}(:\${[-_A-Za-z0-9]+})?'


venv::_version() {
  echo "venv-cli ${_version}"
  return "${_success}"
}

venv::color_echo() {
  local color="$1"
  local string="$2"
  echo -e "${color}${string}${_normal}"
}

venv::raise() {
  if [ -n "$1" ]; then
    venv::color_echo "${_red}" "$1"
  fi
  return "${_fail}"
}

venv::_check_venv_activated() {
  if [ -z "${VIRTUAL_ENV}" ]; then
    venv::raise "No virtual environment activated. Please activate the virtual environment first"
    return "${_fail}"
  fi
  return "${_success}"
}

venv::_check_if_help_requested() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    return "${_success}"
  fi
  return "${_fail}"
}

venv::_check_install_requirements_file() {
  ### Check whether the first argument matches the pattern for a requirements file.
  ### If not, raises error (silently if called with '-q')
  local file_pattern="^.+\.(txt|lock)$"
  if [[ ! "$1" =~ $file_pattern ]]; then
    local message=""
    if [ "$2" != "-q" ]; then
      message="Input file name must end with '.txt' or '.lock', was '$1'"
    fi
    venv::raise "${message}"
    return "$?"
  fi
}

venv::_check_lock_requirements_file() {
  ### Check whether the first argument matches the pattern for a lock file.
  ### If not, raises error (silently if called with '-q')
  local file_pattern="^.+\.lock$"
  if [[ ! "$1" =~ $file_pattern ]]; then
    local message=""
    if [ "$2" != "-q" ]; then
      message="Lock file name must end with '.lock', was '$1'"
    fi
    venv::raise "${message}"
    return "$?"
  fi
}

venv::_get_lock_from_requirements() {
  local requirements_file="$1"
  echo "${requirements_file/.txt/.lock}"
}

venv::_get_requirements_from_lock() {
  local lock_file="$1"
  echo "${lock_file/.lock/.txt}"
}


venv::create() {
  if venv::_check_if_help_requested "$1"; then
    echo "venv create <python-version> [<name>]"
    echo
    echo "Create a new virtual environment using python version <python-version>."
    echo "The virtual environment will be placed in '.venv',"
    echo "and when activated will be named the same as the containing folder."
    echo "It is also possible to specify the name that will be used in the shell prompt."
    echo
    echo 'Requires an executable python of version <python-version> on $PATH'
    echo
    echo "Examples:"
    echo "$ venv create 3.9 my-39-env"
    echo "This will create a virtual environment in '.venv' called 'my-39-env' using python3.9."
    echo
    echo "$ venv create 3.9"
    echo "When run from a folder called 'my-folder', this wil create a virtual environment"
    echo "called 'my-folder' using python3.9."
    return "${_success}"
  fi

  if [ -z "$1" ]; then
    venv::raise "You need to specify the python version to use, e.g. 'venv-create 3.10'"
    return "$?"
  fi

  local python_version="$1"
  local venv_name
  venv_name="$(basename "${PWD}")"

  # Check if a specific name for the "--prompt" was specified
  local venv_prompt='.'
  if [ -n "$2" ]; then
    venv_prompt="$2"
    venv_name="${venv_prompt}"
  fi

  # Check if python command exists
  local python_executable="python${python_version}"
  if ! command -v "${python_executable}" > /dev/null; then
    venv::raise "Couldn't locate '${python_executable}'. Please make sure it is installed and on \$PATH."
    return "$?"
  fi

  local full_python_version="$(${python_executable} -V)"
  venv::color_echo "${_green}" "Creating virtual environment '${venv_name}' using ${full_python_version}"
  ${python_executable} -m venv .venv --prompt "${venv_prompt}"
}


venv::activate() {

  if venv::_check_if_help_requested "$1"; then
    echo "venv activate"
    echo
    echo "Activate the virtual environment located in the current folder."
    echo "This command should be run from the folder containing the '.venv' folder."
    echo
    echo "Examples:"
    echo "$ venv activate"
    return "${_success}"
  fi

  . ./.venv/bin/activate
}


venv::deactivate() {
  if venv::_check_if_help_requested "$1"; then
    echo "venv deactivate"
    echo
    echo "Deactivate the currently activated virtual environment."
    echo
    echo "Examples:"
    echo "$ venv deactivate"
    return "${_success}"
  fi

  if ! deactivate 2> /dev/null; then
    venv::color_echo "${_yellow}" "No virtual environment currently active, nothing to deactivate."
  fi
}


venv::delete() {
  if venv::_check_if_help_requested "$1"; then
    echo "venv delete [-y]"
    echo
    echo "Delete the virtual environment located in the current folder."
    echo "If the environment is currently active, it will be deactivated first."
    echo
    echo "Examples:"
    echo "$ venv delete"
    echo "Are you sure you want to delete the virtual environment in .venv? [y/N]"
    echo "y"
    echo "$ Virtual environment deleted!"
    return "${_success}"
  fi

  if [ ! -d .venv ]; then
    venv::color_echo "${_yellow}" "No virtual environment found, nothing to delete."
    return "${_success}"
  fi

  # If -y is not supplied as input argument, prompt the user for confirmation
  if [ "$1" != "-y" ]; then
    echo "Are you sure you want to delete the virtual environment in .venv? [y/N]"
    read -r response

    local accept_pattern="^([yY][eE][sS]|[yY])$"
    if [[ ! "${response}" =~ $accept_pattern ]]; then
      venv::color_echo "${_yellow}" "Aborting."
      return "${_success}"
    fi
  fi

  venv::color_echo "${_yellow}" "Deleting virtual environment in .venv ..."
  if [ ! -z "${VIRTUAL_ENV}" ]; then
    venv::deactivate
  fi

  if ! rm -rf .venv; then
    # If the virtual environment could not be deleted
    return "${_fail}"
  fi
  venv::color_echo "${_green}" "Virtual environment deleted!"
}


venv::install() {
  if venv::_check_if_help_requested "$1"; then
    echo "venv install [requirement specifiers] [OPTIONS]"
    echo
    echo "Clear the environment, then install requirements from a requirements file, like 'requirements.txt' or 'requirements.lock'."
    echo "Installed packages are then locked into the corresponding .lock-file, e.g. 'venv install -r requirements.txt'" will lock packages into
    echo "'requirements.lock'. This step is skipped if '--skip-lock' or '-s' is specified, or when installing directly from a .lock-file."
    echo
    echo "Optionally, additional requirements can be passed as [requirement specifiers], e.g. 'numpy' or 'pandas >= 2.0'."
    echo "These will first be added to the requirements file, and then the full set of requirements will be installed from the requirements file."
    echo
    echo "The requirements file must have file extension '.txt' or '.lock'."
    echo "If no arguments are passed, a default file name of 'requirements.txt' will be used."
    echo
    echo "Options:"
    echo "  -h, --help                               Show this help and exit."
    echo "  -r, --requirement <requirements file>    Install from the given requirements file. If requirement specifiers"
    echo "                                           are passed, they will be added to the requirements file before installation."
    echo "                                           If not specified, will default to using 'requirements.txt'."
    echo "  -s, --skip-lock                          Skip locking packages to a .lock-file after installation."
    echo "  --pip-args <ARGS>                        Additional arguments to pass through to pip install."
    echo
    echo "Examples:"
    echo "$ venv install"
    echo "$ venv install -r requirements.txt"
    echo "This will install requirements from 'requirements.txt' and lock them into 'requirements.lock'."
    echo
    echo "$ venv install numpy"
    echo "$ venv install numpy -r requirements.txt"
    echo "This will add 'numpy' to 'requirements.txt', then install all requirements from 'requirements.txt'."
    echo
    echo "$ venv install numpy 'pandas >= 2.0' -r requirements/dev-requirements.txt -s --pip-args='--no-cache --pre'"
    echo "This will add 'numpy' and 'pandas >= 2.0' to 'requirements/dev-requirements.txt', then install"
    echo "all requirements from 'dev-requirements.txt' without locking them."
    echo "The arguments '--no-cache' and '--pre' are passed on to 'pip install'."
    return "${_success}"
  fi

  # Parse arguments. Fail if invalid arguments are passed
  local TEMP=$(getopt -o 'r:s' --long 'requirement:,skip-lock,pip-args::' -n 'venv install' -- "$@")
  local _exit="$?"
  if [ "${_exit}" -ne 0 ]; then
    return "${_exit}"
  fi

  local package_args=()  # List of packages to install
  local requirements_file=""
  local skip_lock=false
  local pip_args=""

  eval set -- "$TEMP"  # Unpack the arguments in $TEMP into the positional parameters #1, #2, ...

  # Parse arguments
  while true; do
    # -- marks the end of the options, and anything after it is treated as a positional argument.
    # If "$*" = "--", there are no optional parameters left, and we can break the loop
    if [ "$*" = "--" ]; then
      shift
      break
    fi

    case "$1" in
      "-r" | "--requirement")
        requirements_file="$2"
        shift 2
      ;;
      "-s" | "--skip-lock")
        skip_lock=true
        shift
      ;;
      "--pip-args")
        pip_args="$2"
        shift 2
      ;;
      --)
        # -- marks the end of the options, and anything after it is treated as a positional argument.
        # For venv install, positional arguments are package specifiers
        shift
        package_args+=( "$@" )
        break
      ;;
      *)
        if [ -z "$1" ]; then
          break
        fi
      ;;
    esac
  done

  # Check the specified requirements file
  if [ -z "${requirements_file}" ]; then
    requirements_file="requirements.txt"
    venv::color_echo "${_yellow}" "No requirements file specified, using requirements.txt"
  fi
  if ! venv::_check_install_requirements_file "${requirements_file}"; then
    # Fail if file name doesn't match required format
    return "${_fail}"
  fi

  # Add package specifiers to requirements file if they are not already there
  if [ "${#package_args[@]}" -gt 0 ]; then
    # Create the requirements file if it doesn't already exist, otherwise the next command will fail
    if [ ! -f "${requirements_file}" ]; then
      touch "${requirements_file}"
    fi

    # Make a temporary backup of the requirements file, in case something fails
    venv::_create_backup_file "${requirements_file}"
    if ! venv::_add_packages_to_requirements "${requirements_file}" "${package_args[@]}"; then
      return "${_fail}"
    fi
  fi

  # Clear the environment before running pip install to avoid orphaned packages
  # https://github.com/SallingGroup-AI-and-ML/venv-cli/issues/9
  if ! venv::clear; then
    return "${_fail}"
  fi

  venv::color_echo "${_green}" "Installing requirements from ${requirements_file}"
  # ${pip_args} is unquoted on purpose so it is not passed as a single string argument, but several arguments
  if ! pip install --require-virtualenv --use-pep517 -r "${requirements_file}" ${pip_args}; then
    return "${_fail}"
  fi

  # Lock the installed packages into a .lock-file
  local lock_file="$(venv::_get_lock_from_requirements "${requirements_file}")"
  if "${skip_lock}" || [ "${requirements_file}" = "${lock_file}" ]; then
    venv::color_echo "${_yellow}" "Skipping locking packages to ${lock_file}"
    return "${_success}"
  fi
  venv::lock "${lock_file}"

  # Remove the backup file if everything went well
  venv::_remove_backup_file "${requirements_file}"
}

venv::_add_packages_to_requirements() {
  local requirements_file="$1"
  local package_args=("${@:2}")

  local package_spec
  for package_spec in "${package_args[@]}"; do
    # Use the sed command to remove everything after the package name in the 'package_spec' string
    local package_name="$(echo "${package_spec}" | sed -n 's|^\([a-zA-Z][a-zA-Z0-9_-]*\).*$|\1|p')"
    if [ -z "${package_name}" ]; then
      # Append the package spec directly to the requirements file if the package name could not be extracted
      venv::color_echo "${_yellow}" "Could not extract package name from '${package_spec}', adding directly to ${requirements_file}"
      echo "${package_spec}" >> "${requirements_file}"
      continue
    fi

    # Look for the package name in the requirements file
    if command grep -q "^${package_name}" "${requirements_file}"; then
      # Replace package from requirements file if it's already there
      echo "Replacing existing ${package_name} requirement with '${package_spec}' in ${requirements_file}"
      sed -i "s|^${package_name}.*$|${package_spec}|g" "${requirements_file}"
    else
      # Add package to requirements file if it's not already there
      echo "Adding '${package_spec}' to ${requirements_file}"
      echo "${package_spec}" >> "${requirements_file}"
    fi
  done

  # Sort requirements file after adding packages. LC_COLLATE is set to C to ensure lines beginning with '-'
  # are sorted first, instad of being ignored
  LC_COLLATE=C sort --ignore-case --stable -o "${requirements_file}" "${requirements_file}"
}

venv::uninstall() {
  if venv::_check_if_help_requested "$1"; then
    echo "venv uninstall <package> [...] [OPTIONS]"
    echo
    echo "Remove one or more installed packages from a requirements file, then reinstall the environment from that requirements file."
    echo "The resulting environment will be locked into a .lock-file."
    echo
    echo "The packages to uninsall must be the canonical package names as specified in the requirements file, e.g. 'numpy' or 'scikit-learn'."
    echo "If specified, the requirements file must have file extension '.txt'."
    echo "If no requirements file is passed, the command will assume the file 'requirements.txt' is to be used, and will fail if this file cannot be found."
    echo
    echo "Options:"
    echo "  -h, --help                               Show this help and exit."
    echo "  -r, --requirement <requirements file>    Remove the package(s) from the given requirements file, then reinstall the environment."
    echo "                                           If not specified, will default to using 'requirements.txt' and will fail if this file does not exist."
    echo "  -s, --skip-lock                          Skip locking packages to a .lock-file after reinstallation."
    echo "  --pip-args <ARGS>                        Additional arguments to pass through to pip install on reinstallation."
    echo
    echo "Examples:"
    echo "$ venv uninstall numpy"
    echo "$ venv uninstall numpy -r requirements.txt"
    echo "This will remove the 'numpy' requirement from 'requirements.txt', then reinstall the environment from 'requirements.txt' and lock them into 'requirements.lock'."
    echo
    echo "$ venv uninstall numpy pandas -r requirements/dev-requirements.txt -s --pip-args='--no-cache --pre'"
    echo "This will remove 'numpy' and 'pandas' requirements from 'requirements/dev-requirements.txt', then reinstall"
    echo "all requirements from 'dev-requirements.txt' without locking them."
    echo "The arguments '--no-cache' and '--pre' are passed on to 'pip install' on reinstallation."
    return "${_success}"
  fi

  # Parse arguments. Fail if invalid arguments are passed
  local TEMP=$(getopt -o 'r:s' --long 'requirement:,skip-lock,pip-args::' -n 'venv uninstall' -- "$@")
  local _exit="$?"
  if [ "${_exit}" -ne 0 ]; then
    return "${_exit}"
  fi

  local package_names=()  # List of packages to uninstall
  local requirements_file=""
  local skip_lock=""
  local pip_args=""

  eval set -- "$TEMP"  # Unpack the arguments in $TEMP into the positional parameters #1, #2, ...
  unset TEMP

  # Parse arguments
  while true; do
    # -- marks the end of the options, and anything after it is treated as a positional argument.
    # If "$*" = "--", there are no optional parameters left, and we can break the loop
    if [ "$*" = "--" ]; then
      shift
      break
    fi

    case "$1" in
      "-r" | "--requirement")
        requirements_file="$2"
        shift 2
      ;;
      "-s" | "--skip-lock")
        skip_lock="--skip-lock"
        shift
      ;;
      "--pip-args")
        pip_args="$2"
        shift 2
      ;;
      --)
        # -- marks the end of the options, and anything after it is treated as a positional argument.
        # For venv uninstall, positional arguments are package names
        shift
        package_names+=( "$@" )
        break
      ;;
      *)
        if [ -z "$1" ]; then
          break
        fi
      ;;
    esac
  done

  # Fail if no package names were specified
  if [ "${#package_names[@]}" -eq 0 ]; then
    venv::raise "No packages specified, nothing to uninstall. If you want to uninstall everything, use 'venv clear'."
    return "${_fail}"
  fi

  # Check the specified requirements file
  if [ -z "${requirements_file}" ]; then
    requirements_file="requirements.txt"
    venv::color_echo "${_yellow}" "No requirements file specified, using requirements.txt"
  fi
  if ! venv::_check_install_requirements_file "${requirements_file}"; then
    # Fail if file name doesn't match required format
    return "${_fail}"
  fi

  # Make a temporary backup of the requirements file, in case something fails
  venv::_create_backup_file "${requirements_file}"

  # Remove package names from requirements file
  if ! venv::_remove_packages_from_requirements "${requirements_file}" "${package_names[@]}"; then
    return "${_fail}"
  fi
  if [ "$?" -eq 2 ]; then
    # If none of the packages were found in the requirements file, return without reinstalling
    venv::_remove_backup_file "${requirements_file}"
    return "${_success}"
  fi

  # Remove the backup file if everything went well
  venv::_remove_backup_file "${requirements_file}"

  # Reinstall the environment from the requirements file. Pass through additional arguments
  venv::color_echo "${_green}" "Reinstalling requirements from ${requirements_file}"
  if ! venv::install -r "${requirements_file}" ${skip_lock} --pip-args="${pip_args}"; then
    return "${_fail}"
  fi
}

venv::_remove_packages_from_requirements() {
  local requirements_file="$1"
  local package_names=("${@:2}")

  local package_name
  local packages_removed=0
  for package_name in "${package_names[@]}"; do
    # Check if the package is in the requirements file
    if ! command grep -q "^${package_name}" "${requirements_file}"; then
      venv::color_echo "${_yellow}" "Package '${package_name}' not found in ${requirements_file}, skipping"
      continue
    fi
    # Remove the package from the requirements file
    sed -i "/^${package_name}/d" "${requirements_file}"
    packages_removed=$((packages_removed+1))
    echo "Removed '${package_name}' from ${requirements_file}"
  done

  if [ "${packages_removed}" -eq 0 ]; then
    venv::color_echo "${_yellow}" "None of the specified packages found in ${requirements_file}, nothing to remove"
    return 2
  fi

  # Sort requirements file after removing packages. LC_COLLATE is set to C to ensure lines beginning with '-'
  # are sorted first, instad of being ignored
  LC_COLLATE=C sort --ignore-case --stable -o "${requirements_file}" "${requirements_file}"
}

venv::_create_backup_file() {
  local file="$1"
  if [ -f "${file}" ]; then
    cp "${file}" "${file}.bak"
  fi
}

venv::_remove_backup_file() {
  local backup_file="$1"
  if [ -f "${backup_file}.bak" ]; then
    rm "${backup_file}.bak"
  fi
}

venv::lock() {
  if venv::_check_if_help_requested "$1"; then
    echo "venv lock [<lock file>|<lock file prefix>]"
    echo
    echo "Lock all installed package versions and write them to <lock file>."
    echo "The <lock file> must have the file extension '.lock'."
    echo
    echo "If <lock file prefix> is specified instead, locks the requirements to"
    echo "a file called '<lock file prefix>-requirements.lock', e.g."
    echo "'venv lock dev' locks requirements to 'dev-requirements.lock'."
    echo
    echo "If no <lock file> is specified, defaults to 'requirements.lock'."
    echo
    echo "Examples:"
    echo "$ venv lock"
    echo "This will lock requirements into 'requirements.lock'."
    echo
    echo "$ venv lock dev-requirements.lock"
    echo "This will lock requirements into 'dev-requirements.lock'."
    echo
    echo "$ venv lock ci"
    echo "This will lock requirements into 'ci-requirements.lock'."
    return "${_success}"
  fi

  local lock_file
  if [ -z "$1" ]; then
    # If nothing was passed, default to "requirements.lock"
    lock_file="requirements.lock"

  elif [[ "$1" = *"."* ]]; then
    # If first argument looks like a file name ...
    if venv::_check_lock_requirements_file "$1" -q; then
      # ... and is a lock file
      lock_file="$1"
    else
      venv::raise "Input file(s) had wrong format. See 'venv lock --help' for more info."
      return "$?"
    fi

  else
    # If first argument is not a full filename, assume it is a lock file prefix
    lock_file="$1-requirements.lock"
  fi

  # Write locked requirements into lock file
  pip freeze --require-virtualenv > "${lock_file}"

  venv::color_echo "${_green}" "Locked requirements in ${lock_file}"
}


venv::clear() {
  if venv::_check_if_help_requested "$1"; then
    echo "venv clear"
    echo
    echo "Clear the virtual environment by uninstalling all packages."
    echo
    echo "Examples:"
    echo "$ venv clear"
    return "${_success}"
  fi

  if ! venv::_check_venv_activated; then
    return "${_fail}"
  fi

  venv::color_echo "${_yellow}" "Removing all packages from virtual environment ..."
  pip list --format freeze \
    --exclude pip \
    --exclude setuptools \
    --exclude wheel \
    | cut -d "=" -f1 \
    | xargs --no-run-if-empty pip uninstall --require-virtualenv -y
  venv::color_echo "${_green}" "All packages removed!"
}

venv::help() {
  echo "Utility to help create and manage python virtual environments."
  echo "Lightweight wrapper around pip and venv."
  echo
  echo "Syntax: venv [-h|--help] [-v|--version] <command> [<args>|-h|--help]"
  echo
  echo "The available commands are:"
  echo
  echo "create         Create a new virtual environment in the current folder"
  echo "activate       Activate the virtual environment in the current folder"
  echo "delete         Delete the virtual environment in the current folder"
  echo "install        Install individual packages, or requirements from a requirements file, in the current environment"
  echo "uninstall      Uninstall packages from the current environment and reinstall from a requirements file"
  echo "lock           Lock installed requirements in a '.lock'-file"
  echo "clear          Remove all installed packages in the current environment"
  echo "deactivate     Deactivate the currently activated virtual environment"
  echo "-h, --help     Show this help and exit"
  echo "-v, --version  Show the venv-cli version number and exit"
  echo
  echo "You can also run 'venv <command> --help' to get help with each subcommand."
}


venv::main() {
  subcommand="$1"

  case "${subcommand}" in
    "" | "-h" | "--help")
      venv::help
      ;;

    "-V" | "--version")
      venv::_version
      ;;

    activate \
    | clear \
    | create \
    | deactivate \
    | delete \
    | install \
    | lock \
    | uninstall \
    )
      shift
      venv::"${subcommand}" "$@"
      ;;

    *)
      echo $"Unknown subcommand '${subcommand}'. Try 'venv --help' to see available commands."
      ;;
  esac

  return "$?"
}

venv() {
  venv::main "$@"
  return "$?"
}
