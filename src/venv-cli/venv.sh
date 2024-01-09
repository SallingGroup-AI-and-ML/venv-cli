#!/bin/bash

_success=0
_fail=1

_normal="\033[00m"
_green="\033[32m"
_yellow="\033[01;33m"
_red="\033[31m"

# Version number has to follow pattern "^v\d+\.\d+\.\d+.*$"
_version="v1.5.0"

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
  local file_pattern="^.*?requirements\.(txt|lock)$"
  if [[ ! "$1" =~ $file_pattern ]]; then
    local message=""
    if [ "$2" != "-q" ]; then
      message="Input file name must have format '*requirements.txt' or '*requirements.lock', was '$1'"
    fi
    venv::raise "${message}"
    return "$?"
  fi
}

venv::_check_lock_requirements_file() {
  ### Check whether the first argument matches the pattern for a lock file.
  ### If not, raises error (silently if called with '-q')
  local file_pattern="^.*?requirements\.lock$"
  if [[ ! "$1" =~ $file_pattern ]]; then
    local message=""
    if [ "$2" != "-q" ]; then
      message="Lock file name must have format '*requirements.lock', was '$1'"
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
    echo "venv install [<requirements file>] [--skip-lock|-s] [<install args>]"
    echo
    echo "Clear the environment, then install requirements from <requirements file>,"
    echo "like 'requirements.txt' or 'requirements.lock'."
    echo "Installed packages are then locked into the corresponding .lock-file,"
    echo "e.g. 'venv install requirements.txt' will lock packages into 'requirements.lock'."
    echo "This step is skipped if '--skip-lock' or '-s' is specified, or when installing"
    echo "directly from a .lock-file."
    echo
    echo "The <requirements file> must be in the form '*requirements.[txt|lock]'."
    echo "If no arguments are passed, a default file name of 'requirements.txt'"
    echo "will be used."
    echo
    echo "Additional <install args> are passed on to 'pip install'."
    echo
    echo "Examples:"
    echo "$ venv install"
    echo
    echo "$ venv install dev-requirements.txt"
    echo
    echo "$ venv install requirements.txt --skip-lock|-s --no-cache"
    return "${_success}"
  fi

  local requirements_file
  if [ -z "$1" ] || [ "$1" = "--skip-lock" ] || [ "$1" = "-s" ]; then
    # If no filename was passed
    requirements_file="requirements.txt"

  else
    if ! venv::_check_install_requirements_file "$1"; then
      # Fail if file name doesn't match required format
      return "${_fail}"
    fi

    # If full requirements file (.txt or .lock) passed
    requirements_file="$1"
    shift
  fi

  local skip_lock=false
  if [ "$1" = "--skip-lock" ] || [ "$1" = "-s" ]; then
    skip_lock=true
    shift
  fi

  # Clear the environment before running pip install to avoid orphaned packages
  # https://github.com/SallingGroup-AI-and-ML/venv-cli/issues/9
  venv::clear

  venv::color_echo "${_green}" "Installing requirements from ${requirements_file}"
  if ! pip install --require-virtualenv --use-pep517 -r "${requirements_file}" "$@"; then
    return "${_fail}"
  fi

  local lock_file="$(venv::_get_lock_from_requirements "${requirements_file}")"
  if "${skip_lock}" || [ "${requirements_file}" == "${lock_file}" ]; then
    venv::color_echo "${_yellow}" "Skipping locking packages to ${lock_file}"
    return "${_success}"
  fi

  venv::lock "${lock_file}"
  return "$?"  # Return exit status from venv::lock command
}


venv::lock() {
  if venv::_check_if_help_requested "$1"; then
    echo "venv lock [<lock file>|<lock file prefix>]"
    echo
    echo "Lock all installed package versions and write them to <lock file>."
    echo "The <lock file> must be in the form '*requirements.lock'."
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
  pip freeze --require-virtualenv \
    | cut -d "@" -f1 \
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
  echo "install        Install requirements from a requirements file in the current environment"
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

    create \
    | activate \
    | delete \
    | install \
    | lock \
    | clear \
    | deactivate \
    )
      shift
      venv::"${subcommand}" "$@"
      ;;

    *)
      echo $"Unknown subcommand '${subcommand}'. Try 'venv --help' to see available commands."
      ;;

  esac
}

venv() {
  venv::main "$@"
}
