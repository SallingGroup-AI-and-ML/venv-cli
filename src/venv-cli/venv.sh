#!/bin/bash

_normal="\033[00m"
_green="\033[32m"
_yellow="\033[01;33m"
_red="\033[31m"

# Version number has to follow pattern "^v\d+\.\d+\.\d+.*$"
_version="v1.0.2"

venv::_version() {
  echo "venv-cli ${_version}"
  return 0
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
  return 1
}

venv::_check_if_help_requested() {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    return 0
  fi
  return 1
}

venv::_check_install_requirements_file() {
  local file_pattern="^.*?requirements\.(txt|lock)"
  if [[ ! "$1" =~ $file_pattern ]]; then
    venv::raise "Input file name must have format '*requirements.txt' or '*requirements.lock'"
    return "$?"
  fi
}

venv::_check_lock_requirements_file() {
  local file_pattern="^.*?requirements\.lock$"
  if [[ ! "$1" =~ $file_pattern ]]; then
    venv::raise "Lock file name must have format '*requirements.lock'"
    return "$?"
  fi
}


venv::create() {
  if venv::_check_if_help_requested "$1"; then
    echo "venv create <python-version> [<name>]"
    echo
    echo "Create a new virtual environment using python version <python-version>."
    echo "The virtual environment will be placed in '.venv', "
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
    echo "When run from a folder called 'my-folder', this wil create a virtual environment "
    echo "called 'my-folder' using python3.9."
    return 0
  fi

  if [ -z "$1" ]; then
    venv::raise "You need to specify the python version to use, e.g. 'venv-create 3.10'"
    return "$?"
  fi

  local python_version="$1"
  local venv_prompt='.'
  local venv_name
  venv_name="$(basename "${PWD}")"

  # Check if a specific name for the "--prompt" was specified
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

  venv::color_echo "${_green}" "Creating virtual environment '${venv_name}' using python${python_version}"
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
    return 0
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
    return 0
  fi

  if ! deactivate 2> /dev/null; then
    venv::color_echo "${_yellow}" "No virtual environment currently active, nothing to deactivate."
  fi
}


venv::install() {
  if venv::_check_if_help_requested "$1"; then
    echo "venv install [<requirements file>] [--skip-lock]"
    echo
    echo "Install requirements from <requirements file>, like 'requirements.txt' or 'requirements.lock'."
    echo "Installed packages are then locked into the corresponding .lock-file, "
    echo "e.g. 'venv install requirements.txt' will lock packages into 'requirements.lock'."
    echo "This step is skipped if '--skip-lock' is specified, or when installing directly from a .lock-file."
    echo
    echo "The <requirements file> must be in the form '*requirements.[txt|lock]'."
    echo "If no arguments are passed, a default file name of 'requirements.txt' will be used."
    echo
    echo "Examples:"
    echo "$ venv install"
    echo
    echo "$ venv install dev-requirements.txt"
    echo
    echo "$ venv install requirements.txt --skip-lock"
    return 0
  fi

  local requirements_file
  if [ -z "$1" ] || [ "$1" = "--skip-lock" ]; then
    # If no argument passed
    requirements_file="requirements.txt"

  else
    if ! venv::_check_install_requirements_file "$1"; then
      # Fail if file name doesn't match required format
      return 1
    fi

    # If full requirements file (.txt or .lock) passed
    requirements_file="$1"
    shift
  fi

  local skip_lock=false
  if [ "$1" = "--skip-lock" ]; then
    skip_lock=true
    shift
  fi

  venv::color_echo "${_green}" "Installing requirements from ${requirements_file}"
  if ! pip install --require-virtualenv -r "${requirements_file}" "$@"; then
    return 1
  fi

  local lock_file="${requirements_file/.txt/.lock}"  # Replace ".txt" with ".lock"
  if "${skip_lock}" || [ "${requirements_file}" = "${lock_file}" ]; then
    venv::color_echo "${_yellow}" "Skipping locking packages to ${lock_file}"
    return 0
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
    echo "If <lock file prefix> is specified instead, locks the requirements to "
    echo "a file called '<lock file prefix>-requirements.lock'."
    echo
    echo "If no <lock file> is specified, defaults to 'requirements.lock'."
    echo
    echo "Examples:"
    echo "$ venv lock"
    echo
    echo "$ venv lock dev-requirements.lock"
    echo
    echo "$ venv lock dev"
    echo "This will lock the requirements into a file named 'dev-requirements.lock'."
    return 0
  fi

  local lock_file
  # If nothing passed, default to "requirements.lock"
  if [ -z "$1" ]; then
    lock_file="requirements.lock"

  elif [[ "$1" = *"."* ]]; then
    if venv::_check_lock_requirements_file "$1"; then
      lock_file="$1"
      shift
    else
      return 1
    fi

  else
    lock_file="$1-requirements.lock"
  fi

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
    return 0
  fi

  venv::color_echo "${_yellow}" "Removing all packages from virtual environment ..."
  pip freeze --require-virtualenv \
    | cut -d "@" -f1 \
    | xargs --no-run-if-empty pip uninstall --require-virtualenv -y
  venv::color_echo "${_green}" "All packages removed!"
}


venv::sync() {
  if venv::_check_if_help_requested "$1"; then
    echo "venv sync [<lock file>]"
    echo
    echo "Remove all installed packages from the environment (venv clear) "
    echo "and install all packages specified in <lock file>."
    echo "The <lock file> must be in the form '*requirements.lock'."
    echo
    echo "If no <lock file> is specified, defaults to 'requirements.lock'."
    echo
    echo "Examples:"
    echo "$ venv sync dev-requirements.lock"
    echo "Clears the environment and installs requirements from 'dev-requirements.lock'."
    echo
    echo "$ venv sync"
    echo "Tries to install from 'requirements.lock'."
    echo "Clears the environment and installs requirements from 'requirements.lock'."
    return 0
  fi

  local lock_file
  if [ -z "$1" ]; then
    # If no argument passed
    lock_file="requirements.lock"

  # If full lock file passed
  else
    if ! venv::_check_lock_requirements_file "$1" "Can only sync using .lock file"; then
      return 1
    fi

    lock_file="$1"
    shift
  fi

  venv::clear
  venv::install "${lock_file}" "$@"
  return "$?"  # Return exit status from venv::install command
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
  echo "install        Install requirements from a requirements file in the current environment"
  echo "lock           Lock installed requirements in a '.lock'-file"
  echo "clear          Remove all installed packages in the current environment"
  echo "sync           Run 'venv clear', then install locked requirements from a "
  echo "               '.lock'-file in the current environment"
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
    | install \
    | lock \
    | clear \
    | sync \
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
