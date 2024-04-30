# #############################################################################
# Deletes all local branches which do not exist on remote
# #############################################################################

function clean_branches() {
    while true; do
        local response=$(prompt_user "Do you wish to delete all local branches which do not exist on remote? [y/N]" "N")

        case $response in
            [yY])
                git fetch -p ; git branch -r | awk '{print $1}' | egrep -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk '{print $1}' | xargs git branch -d
                log INFO "Obosolete branches pruned"
                break
                ;;
            [nN]|"")
                exit 1
                ;;
            *)
                log WARN "Invalid input"
                ;;
        esac
    done
}
