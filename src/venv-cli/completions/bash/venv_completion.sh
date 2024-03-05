# bash completion for venv                                -*- shell-script -*-

_venv() {
    local first_word second_word cur_word prev_word _subcommands subcommands help_options
    first_word="${COMP_WORDS[0]}"
    second_word="${COMP_WORDS[1]}"
    cur_word="${COMP_WORDS[COMP_CWORD]}"
    prev_word="${COMP_WORDS[COMP_CWORD-1]}"

    _subcommands="activate clear create deactivate delete install lock uninstall"
    subcommands=( $(compgen -W "${_subcommands}" -- "${cur_word}") )
    help_options=( $(compgen -W "-h --help" -- "${cur_word}") )

    compopt -o nosort
    if [ "${first_word}" != "venv" ]; then
        return
    fi

    if [ "${prev_word}" == "venv" ]; then
        # If only 'venv' has been entered, generate list of subcommands and options
        COMPREPLY+=( ${subcommands[*]} )
        COMPREPLY+=( ${help_options[*]} )

        local version_options
        version_options=( $(compgen -W "-V --version" -- "${cur_word}") )
        COMPREPLY+=( ${version_options[*]} )
        return
    fi

    # Generate completions for subcommand options
    case "${second_word}" in
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
        "delete")
            # Generate completion for help_options plus the '-y' option
            COMPREPLY+=( ${help_options[*]} )
            COMPREPLY+=( $(compgen -W "-y" -- "${cur_word}") )
            ;;
        "install")
            case "${prev_word}" in
                "-r"|"--requirement")
                    # Generate completions for requirement and lock file paths if -r or --requirement is used
                    COMPREPLY+=( $(compgen -f -X '!(*.txt|*.lock)' -- "${cur_word}" | sort) )
                    compopt -o plusdirs +o nosort  # Add directories after generated completions
                    ;;
                *)
                    COMPREPLY+=( ${help_options[*]} )
                    COMPREPLY+=( $(compgen -W "-r --requirement -s --skip-lock --pip-args" -- "${cur_word}") )
                    ;;
            esac
            ;;
        "uninstall")
            case "${prev_word}" in
                "-r"|"--requirement")
                    # Generate completions for requirements file paths if -r or --requirement is used
                    COMPREPLY+=( $(compgen -f -X '!(*.txt)' -- "${cur_word}" | sort) )
                    compopt -o plusdirs +o nosort  # Add directories after generated completions
                    ;;
                *)
                    COMPREPLY+=( ${help_options[*]} )
                    COMPREPLY+=( $(compgen -W "-r --requirement -s --skip-lock --pip-args" -- "${cur_word}") )
                    ;;
            esac
            ;;
        "lock")
            # Generate completions for lock file paths
            COMPREPLY+=( $(compgen -f -X '!(*.lock)' -- "${cur_word}" | sort) )
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
}

complete -F _venv venv

# ex: filetype=sh
