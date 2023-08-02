#!/bin/bash

_success=0
_fail=1

_normal="\033[00m"
_green="\033[32m"
_yellow="\033[01;33m"
_red="\033[31m"

# Version number has to follow pattern "^v\d+\.\d+\.\d+.*$"
_version="v1.1.0"

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


venv::install() {
  if venv::_check_if_help_requested "$1"; then
    echo "venv install [<requirements file>] [--skip-lock] [<install args>]"
    echo
    echo "Install requirements from <requirements file>, like 'requirements.txt'"
    echo "or 'requirements.lock'."
    echo "Installed packages are then locked into the corresponding .lock-file,"
    echo "e.g. 'venv install requirements.txt' will lock packages into 'requirements.lock'."
    echo "This step is skipped if '--skip-lock' is specified, or when installing"
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
    echo "$ venv install requirements.txt --skip-lock --no-cache"
    return "${_success}"
  fi

  local requirements_file
  if [ -z "$1" ] || [ "$1" = "--skip-lock" ]; then
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
  if [ "$1" = "--skip-lock" ]; then
    skip_lock=true
    shift
  fi

  venv::color_echo "${_green}" "Installing requirements from ${requirements_file}"
  if ! pip install --require-virtualenv --use-pep517 -r "${requirements_file}" "$@"; then
    return "${_fail}"
  fi

  local lock_file="$(venv::_get_lock_from_requirements "${requirements_file}")"
  if "${skip_lock}" || [ "${requirements_file}" == "${lock_file}" ]; then
    venv::color_echo "${_yellow}" "Skipping locking packages to ${lock_file}"
    return "${_success}"
  fi

  venv::lock "${requirements_file}" "${lock_file}"
  return "$?"  # Return exit status from venv::lock command
}


venv::_fill_credentials() {
  ### Read VCS URL auth from requirements file and fill in lock file URLs
  local requirements_file="$1"
  local lock_file="$2"

  # Loop over every line in requirements file
  while IFS= read -r req_line; do
    # Extract package name from requirement
    local package=$(echo "${req_line}" | command awk '{print $1}')
    # Extract VCS URL from requirement
    local url_req=$(echo "${req_line}" | command awk '{print $3}')

    # Extract environment variable(s) from the URL
    local env_vars=$(echo "${url_req}" | command grep -oE "${_env_var_auth_pattern}")
    if [ -z "${env_vars}" ]; then
      # No env vars in the url (or no url at all), skip line
      continue
    fi

    # Use sed to fill in $env_vars after "https://"-section, so a line like
    # 'asdf-lib @ git+https://github.com/someuser/asdf-lib@commithash'
    # becomes e.g.
    # 'asdf-lib @ git+https://${AUTH_TOKEN}@github.com/someuser/asdf-lib@commithash'
    # or
    # 'asdf-lib @ git+https://${USERNAME}:${PASSWORD}@github.com/someuser/asdf-lib@commithash'
    local before_auth_pattern="^(${package} @ [a-zA-Z+]*?https?://)"
    local after_auth_pattern="(.*?)$"
    local fill_pattern="\1${env_vars}@\2"
    command sed -i -E "s|${before_auth_pattern}${after_auth_pattern}|${fill_pattern}|" "${lock_file}"

  done < "${requirements_file}"
}


venv::lock() {
  if venv::_check_if_help_requested "$1"; then
    echo "venv lock [<lock file>|<lock file prefix>]"
    echo "venv lock <requirements file> <lock file>"
    echo
    echo "Lock all installed package versions and write them to <lock file>."
    echo "The <lock file> must be in the form '*requirements.lock'."
    echo
    echo "If <lock file prefix> is specified instead, locks the requirements to"
    echo "a file called '<lock file prefix>-requirements.lock'."
    echo
    echo "If no <lock file> is specified, defaults to 'requirements.lock'."
    echo
    echo "This function uses 'pip freeze' to lock the requirements, but since"
    echo "'pip freeze' does not include the auth-part of VCS URLs, this command"
    echo "needs a reference 'requirements.txt'-file to extract the credentials from."
    echo
    echo "In the first form, where only <lock file> is specified, this command"
    echo "looks for a reference <requirements file> with the same stem as <lock file>,"
    echo "and with a '.txt' extension, e.g. 'venv lock dev-requirements.lock' will look"
    echo "for a reference file 'dev-requirements.txt'."
    echo
    echo "In the second form, both the reference <requirements file> and the <lock file>"
    echo "are specified."
    echo
    echo "Examples:"
    echo "$ venv lock"
    echo "This will lock requirements into 'requirements.lock',"
    echo "referencing 'requirements.txt'."
    echo
    echo "$ venv lock dev-requirements.lock"
    echo "This will lock requirements into 'dev-requirements.lock',"
    echo "referencing 'dev-requirements.txt'."
    echo
    echo "$ venv lock dev"
    echo "This will lock requirements into 'dev-requirements.lock',"
    echo "referencing 'dev-requirements.txt'."
    return "${_success}"
  fi

  local requirements_file
  local lock_file
  if [ -z "$1" ]; then
    # If nothing was passed, default to "requirements.lock" with "requirements.txt"
    # as reference
    lock_file="requirements.lock"
    requirements_file="requirements.txt"

  elif [[ "$1" = *"."* ]]; then
    # If first argument looks like a file name ...

    if venv::_check_lock_requirements_file "$1" -q; then
      # In this case, the first argument is a lock file
      lock_file="$1"
      requirements_file="$(venv::_get_requirements_from_lock "$1")"
      shift

    elif $(venv::_check_install_requirements_file "$1" -q \
        && venv::_check_lock_requirements_file "$2" -q); then
      # In this case, the first argument is a requirements file and the second
      # argument is a lock file
      requirements_file="$1"
      lock_file="$2"
      shift 2

    else
      venv::raise "Input file(s) had wrong format. See 'venv lock --help' for more info."
      return "$?"
    fi

  else
    # If first argument is not a full filename, assume it is a lock file prefix
    lock_file="$1-requirements.lock"
    requirements_file="$1-requirements.txt"
  fi

  if [ ! -f "${requirements_file}" ]; then
    venv::raise "No reference requirements file found with name '${requirements_file}', aborting."
    return "$?"
  fi

  # Write locked requirements into lock file
  pip freeze --require-virtualenv > "${lock_file}"

  # Since 'pip freeze' does not include the auth-part of VCS URLs, we have to
  # get those from the reference requirements file
  if ! venv::_fill_credentials "${requirements_file}" "${lock_file}"; then
    return "${_fail}"
  fi

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
    echo "Remove all installed packages from the environment (venv clear)"
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
    return "${_success}"
  fi

  local lock_file
  if [ -z "$1" ]; then
    # If no argument passed
    lock_file="requirements.lock"

  # If full lock file passed
  else
    if ! venv::_check_lock_requirements_file "$1" "Can only sync using .lock file"; then
      return "${_fail}"
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
  echo "sync           Run 'venv clear', then install locked requirements from a"
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
