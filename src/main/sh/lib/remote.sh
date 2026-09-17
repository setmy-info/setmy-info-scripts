# Copyright (C) 2026 Imre Tabur <imre.tabur@mail.ee>
#
# SSH connection helper library shared by smi-upload and smi-remote-exec.
#
# Connection settings come from the environment, so one set of variables serves
# an upload and the remote commands that follow it:
#
#     SMI_REMOTE_HOST      remote host name or IP address, no default
#     SMI_REMOTE_PORT      remote SSH port, default 22
#     SMI_REMOTE_USER      remote user name, default the current login name
#     SMI_REMOTE_PASSWORD  remote password, default empty (key based authentication)

REMOTE_HOST="${SMI_REMOTE_HOST:-}"
REMOTE_PORT="${SMI_REMOTE_PORT:-22}"
REMOTE_USER="${SMI_REMOTE_USER:-$(id -un)}"
REMOTE_PASSWORD="${SMI_REMOTE_PASSWORD:-}"
# Command prefix for scp or ssh, "sshpass -e" when a password is used, empty otherwise.
REMOTE_SSHPASS=""
# accept-new answers the "unknown host" question without a terminal, but still refuses a changed host key.
REMOTE_HOST_KEY_CHECKING="StrictHostKeyChecking=accept-new"

# Overrides REMOTE_USER, REMOTE_HOST and REMOTE_PORT from one [USER@]HOST[:PORT] argument.
remoteParseServer() {
    _SERVER="$1"
    case "${_SERVER}" in
        *@*)
            REMOTE_USER="${_SERVER%%@*}"
            _SERVER="${_SERVER#*@}"
            ;;
    esac
    case "${_SERVER}" in
        *:*)
            REMOTE_HOST="${_SERVER%%:*}"
            REMOTE_PORT="${_SERVER##*:}"
            ;;
        *)
            REMOTE_HOST="${_SERVER}"
            ;;
    esac
}

remoteRequireHost() {
    if [ -z "${REMOTE_HOST}" ]; then
        printf "%s: no remote host given, set SMI_REMOTE_HOST\n" "$(basename "$0")" >&2
        return 1
    fi
}

# The password goes through the SSHPASS environment variable, sshpass -p would show it in the process list.
remotePreparePassword() {
    if [ -z "${REMOTE_PASSWORD}" ]; then
        return 0
    fi
    if ! command -v sshpass > /dev/null 2>&1; then
        printf "%s: sshpass is required for password authentication\n" "$(basename "$0")" >&2
        return 1
    fi
    SSHPASS="${REMOTE_PASSWORD}"
    export SSHPASS
    REMOTE_SSHPASS="sshpass -e"
}

remoteDestination() {
    printf "%s@%s" "${REMOTE_USER}" "${REMOTE_HOST}"
}

# Single quotes one argument for the remote shell. A leading ~ or ~/ stays unquoted,
# so it expands to the remote user's home, not the local one.
remoteQuoteArgument() {
    _ARGUMENT="$1"
    case "${_ARGUMENT}" in
        '~')
            printf "~"
            return 0
            ;;
        '~/'*)
            printf "~/"
            _ARGUMENT="${_ARGUMENT#??}"
            ;;
    esac
    # The trailing x keeps trailing newlines of the argument through the command substitution.
    _ESCAPED=$(printf "%sx" "${_ARGUMENT}" | sed "s/'/'\\\\''/g")
    printf "'%s'" "${_ESCAPED%x}"
}

# Prints the arguments as one command line the remote shell splits back into the same arguments.
remoteQuoteCommand() {
    _SEPARATOR=""
    for _ARGUMENT in "$@"; do
        printf "%s" "${_SEPARATOR}"
        remoteQuoteArgument "${_ARGUMENT}"
        _SEPARATOR=" "
    done
}
