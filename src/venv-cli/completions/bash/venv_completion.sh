# bash completion for venv                                -*- shell-script -*-

_venv() {
    local cur_word prev_word _subcommands subcommands help_options
    cur_word="${COMP_WORDS[COMP_CWORD]}"
    prev_word="${COMP_WORDS[COMP_CWORD-1]}"

    _subcommands="activate clear create deactivate install lock sync"
    subcommands=( $(compgen -W "${_subcommands}" -- "${cur_word}") )
    help_options=( $(compgen -W "-h --help" -- "${cur_word}") )

    # Generate completions for subcommand options
    compopt -o nosort
    case "${prev_word}" in
        "venv")
            # If only 'venv' has been entered, generate list of subcommands and options
            COMPREPLY+=( ${subcommands[*]} )
            COMPREPLY+=( ${help_options[*]} )

            local version_options
            version_options=( $(compgen -W "-V --version" -- "${cur_word}") )
            COMPREPLY+=( ${version_options[*]} )
            ;;
        "create")
            # Generate list of all available python3 versions

            # The command below does the following, by line:
            # * List all python commands, e.g. "python3", "python3.10-config", ...
            # * Select only "python3.X" or "python3.XX"
            # * Remove the "python", leaving the version number
            # * Select unique entries, sorted by numerical value
            local python_versions
            python_versions=( $( \
                    compgen -c "python${cur_word}" \
                    | grep -P '^python3.\d+$' \
                    | sed 's|python||' \
                    | sort -n --unique \
                ) )
            COMPREPLY+=( ${python_versions[*]} )
            COMPREPLY+=( ${help_options[*]} )
            ;;
        "install"|"lock")
            # Generate completions for requirement and lock file paths
            COMPREPLY+=( $(compgen -f -X '!(*.txt|*.lock)' -- "${cur_word}" | sort) )
            COMPREPLY+=( ${help_options[*]} )
            compopt -o plusdirs +o nosort  # Add directories after generated completions
            ;;
        "sync")
            # Generate completions for lock file paths
            COMPREPLY+=( $(compgen -f -X '!*.lock' -- "${cur_word}" | sort) )
            COMPREPLY+=( ${help_options[*]} )
            compopt -o plusdirs +o nosort  # Add directories after generated completions
            ;;
        "activate"|"deactivate"|"clear")
            # Only generate help options
            COMPREPLY+=( ${help_options[*]} )
            ;;
        "-V"|"--version")
            # Nothing to generate
            ;;
        *)
            # Nothing to generate
            ;;
    esac

    # Special case for 'venv lock requirements.txt <TAB>', where only *.lock files should be suggested
    if [ "${COMP_WORDS[COMP_CWORD-2]}" == "lock" ] && [[ "${prev_word}" =~ ^.*\.txt$ ]]; then
        COMPREPLY+=( $(compgen -f -X '!*.lock' -- "${cur_word}" | sort) )
        compopt -o plusdirs +o nosort  # Add directories after generated completions
    fi
}

complete -F _venv venv

# ex: filetype=sh
