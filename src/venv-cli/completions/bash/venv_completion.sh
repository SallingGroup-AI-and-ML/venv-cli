# bash completion for venv                                -*- shell-script -*-

_venv() {
    local cur_word prev_word subcommands fill_list
    cur_word="${COMP_WORDS[COMP_CWORD]}"
    prev_word="${COMP_WORDS[COMP_CWORD-1]}"
    subcommands="create activate install lock clear sync deactivate -V --version"
    command_options="-h --help"

    if [ "${prev_word}" == "venv" ]; then
        fill_list="${subcommands} ${command_options}"
    else
        fill_list="${command_options}"
    fi
    COMPREPLY=($(compgen -W "${fill_list}" -- "${cur_word}"))
}

complete -F _venv venv

# ex: filetype=sh
