#compdef venv

local curcontext="${curcontext}" state line
typeset -A opt_args

# List of available options
local -a subcommands=("create" "activate" "install" "lock" "clear" "deactivate" "-V" "--version")
local -a command_options=("-h" "--help")
local -a all=("${subcommands[@]} ${command_options[@]}")

case "${words}[2]" in
    "${subcommands}")
        # Complete the options if the second word matches any of the available options
        _describe "option" command_options
        ;;
    *)
        case "${words}[1]" in
            venv)
                # Complete the base command options if the first word is "venv"
                _describe "option" all
                ;;
            # *)
            #     # If none of the above matches, complete file paths
            #     _files
            #     ;;
        esac
        ;;
esac
