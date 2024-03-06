#!/usr/bin/env bash
_src_dir="${PWD}/src/venv-cli"
_install_dir="/usr/local/share/venv"
_source_comment="# Source function script for 'venv' command"

set -e

install_common() {
  local rcfile="$1"
  local completion_file="$2"
  local completion_target="$3"

  set -x
  sudo mkdir -p /usr/local/share/venv
  sudo cp "${_src_dir}/venv.sh" "${_install_dir}/venv"
  sudo cp "${_src_dir}/uninstall.sh" "${_install_dir}/uninstall.sh"

  if [ -n "${completion_file}" ]; then
    sudo cp "${completion_file}" "${completion_target}"
  fi

  # If line does not already exist in the rc file,
  # append line to the shell config file to source the venv-cli script
  if ! command grep -q "${_source_comment}" "${rcfile}"; then
    echo "${_source_comment}" >> "${rcfile}"
    echo "source ${_install_dir}/venv" >> "${rcfile}"
  fi

  { set +x; } 2>/dev/null
}

install_bash() {
  local rcfile="${HOME}/.bashrc"
  local completion_file="${_src_dir}/completions/bash/venv_completion.sh"
  local completion_target="/usr/share/bash-completion/completions/venv"
  PS4="\000"  # Remove '++' from beginning of lines while printing commands

  install_common "${rcfile}" "${completion_file}" "${completion_target}"
}

install_zsh() {
  local rcfile="${HOME}/.zshrc"
  # local completion_file="${_src_dir}/completions/zsh/venv_completion.sh"
  # local completion_target="/usr/local/share/zsh/site-functions/_venv"
  echo "Command completions currently not supported for zsh"

  install_common "${rcfile}"
  if ! command grep -q "${_source_comment}" "${rcfile}"; then
    echo "fpath+=( ${_install_dir} )" >> "${rcfile}"
    echo "autoload -Uz venv" >> "${rcfile}"
  fi
}

main() {
  local shell="$1"

  case "${shell}" in
    "" | "bash")
      install_bash
      ;;

    "zsh")
      install_zsh
      ;;

    *)
      echo "No install script available for '${shell}'."
      echo "Use a different shell or install manually by adding 'source venv-cli/src/venv-cli/venv-cli.sh' to your shell's RC-file"
      return 1
      ;;
  esac

  echo "venv installed"
}

main "$@"
