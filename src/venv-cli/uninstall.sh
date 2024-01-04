#!/usr/bin/env bash
_venv_dir="/usr/local/share/venv"

set -e
PS4="\000"

post() {
  sudo rm ${_venv_dir}/* || true
  sudo rm -r "${_venv_dir}" || true
}

backup_rcfile() {
  local rcfile="$1"

  echo -e "# This backup file was created by venv-cli during uninstall" > "${rcfile}.old"
  cat "${rcfile}" >> "${rcfile}.old"
  echo "Created backup of ${rcfile} at ${rcfile}.old"
}

remove_source_lines() {
  # Remove the 'source' lines and the comment above it
  local source_lines_to_remove=$(("$1" - 1))
  local rcfile="$2"

  # Remove a specific number of lines from the rc file.
  # The result is then redirected to a .tmp rc file, which is then moved to the original rc file.
  local delete_pattern=",+${source_lines_to_remove}d"
  sed "\|\# Source function script for 'venv' command|${delete_pattern}" < "${rcfile}" > "${rcfile}.tmp"
  mv "${rcfile}.tmp" "${rcfile}"
}

uninstall_common() {
  local rcfile="$1"
  local completion_target="$2"
  local lines_to_remove="$3"

  if command grep -q "${_venv_dir}/venv" "${rcfile}"; then
    backup_rcfile "${rcfile}"
    remove_source_lines "${lines_to_remove}" "${rcfile}"
  fi

  if [ -f "${completion_target}" ]; then
    sudo rm "${completion_target}"
  fi
}

uninstall_bash() {
  local rcfile="${HOME}/.bashrc"
  local completion_target="/usr/share/bash-completion/completions/venv"
  local rcfile_source_lines=2

  uninstall_common "${rcfile}" "${completion_target}" "${rcfile_source_lines}"

  echo "venv command and completions removed from bash"
}

uninstall_zsh() {
  local rcfile="${HOME}/.zshrc"
  local completion_target="/usr/local/share/zsh/site-functions/_venv"
  local rcfile_source_lines=4

  uninstall_common "${rcfile}" "${completion_target}" "${rcfile_source_lines}"

  echo "venv command and completions removed from zsh"
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
