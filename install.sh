#!/usr/bin/env bash
_src_dir="${PWD}/src/venv-cli"
_install_dir="/usr/local/share/venv"

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

  # Append line to the shell config file to source the script
  echo -e "\n# Source function script for 'venv' command" >> "${rcfile}"
  echo ". ${_install_dir}/venv" >> "${rcfile}"
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
  echo "fpath+=( ${_install_dir} )" >> "${rcfile}"
  echo "autoload -Uz venv" >> "${rcfile}"
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
      echo "Use a different shell or install manually by adding 'source venv-cli/0src/venv-cli/venv-cli.sh' to your shell's RC-file"
      return 1
      ;;
  esac

  echo "venv installed"
}

main "$@"
