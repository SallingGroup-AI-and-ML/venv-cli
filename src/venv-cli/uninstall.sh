#!/usr/bin/env bash
_venv_dir="/usr/local/share/venv"

set -e
PS4="\000"

post() {
  sudo rm ${_venv_dir}/* || true
  sudo rm -r "${_venv_dir}" || true
}

uninstall_common() {
  local rcfile="$1"
  local completion_target="$2"

  # Remove the line from shell config that sources the script
	sed -i "\|.*Source autocompletions for 'venv' command|d" "${rcfile}"
	sed -i "\|\. ${_venv_dir}/venv|d" "${rcfile}"

  if [ -f "${completion_target}" ]; then
    sudo rm "${completion_target}"
  fi
}

uninstall_bash() {
  local rcfile="${HOME}/.bashrc"
  local completion_target="/usr/share/bash-completion/completions/venv"

  uninstall_common "${rcfile}" "${completion_target}"
}

uninstall_zsh() {
  local rcfile="${HOME}/.zshrc"
  local completion_target="/usr/local/share/zsh/site-functions/_venv"

  uninstall_common "${rcfile}" "${completion_target}"
  sed -i "\|fpath+=( ${_install_dir} )|d" "${rcfile}"
  sed -i "\|autoload -Uz venv|d" "${rcfile}"
}

main() {
  if [ -f "${HOME}/.bashrc" ]; then
    uninstall_bash
  fi

  if [ -f "${HOME}/.zshrc" ]; then
    uninstall_zsh
  fi

  post
  echo "venv uninstalled"
}

main
