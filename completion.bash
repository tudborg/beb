_beb() 
{
    local cur prev opts base
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"


    #
    #  Complete the arguments to some of the basic commands.
    #
    case "${prev}" in
        beb)
            opts="build environment release upload version"
            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
            return 0
            ;;
        version)
            opts="create list"
            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
            return 0
            ;;
        environment)
            opts="info list"
            COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
            return 0
            ;;
        *)
            ;;
    esac
   return 0
}
complete -F _beb beb