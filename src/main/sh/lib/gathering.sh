# Copyright (C) 2026 Imre Tabur <imre.tabur@mail.ee>
#
# Helper functions for the smi-pentest-gather profiles.
#
# Everything here only reads. The functions print what they found to standard output, which the
# command redirects into the gathering file. restorecon is only ever called with -n, the dry run.
#
# Two kinds of function:
#
#   show*, run*, selinux*   gather: print facts for a human and for an agent to read
#   expect*, require*       check: print OK or a finding, and record the finding for the summary
#
# A check that fails does not end the gathering: the point is to collect every problem in one
# document. Findings are counted in FINDING_PROBLEMS and FINDING_WARNINGS and listed again by
# findingsSummary at the end of the file.
#
# Secrets are never printed. A private key, a password file or a token list is reported with
# secretFile, which shows the name, the mode, the owner and the SELinux label only.

GATHERING_DIR=$(smi-lib-location)/gathering

FINDINGS=''
FINDING_PROBLEMS=0
FINDING_WARNINGS=0

section() {
    printf '\n## %s\n' "$*"
}

topic() {
    printf '\n### %s\n' "$*"
}

note() {
    printf '%s\n' "$*"
}

# ==========================================================================
# Findings
# ==========================================================================

ok() {
    printf 'OK: %s\n' "$*"
}

problem() {
    printf 'PROBLEM: %s\n' "$*"
    FINDING_PROBLEMS=$((FINDING_PROBLEMS + 1))
    FINDINGS="${FINDINGS}- PROBLEM: $*
"
}

warning() {
    printf 'WARNING: %s\n' "$*"
    FINDING_WARNINGS=$((FINDING_WARNINGS + 1))
    FINDINGS="${FINDINGS}- WARNING: $*
"
}

# Printed by the command after every profile.
findingsSummary() {
    section 'Findings'
    note 'Collected by the checks of the profiles above. OK lines are left there, in context.'
    printf '\nProblems: %s, warnings: %s\n' "${FINDING_PROBLEMS}" "${FINDING_WARNINGS}"
    if [ -n "${FINDINGS}" ]; then
        printf '\n%s' "${FINDINGS}"
    else
        printf '\nNothing found by the automatic checks. They are a first pass, not an audit.\n'
    fi
}

# ==========================================================================
# Gathering
# ==========================================================================

runCommand() {
    printf '\n```sh\n$ %s\n' "$*"
    if ! "$@" 2>&1; then
        printf '(exited %s)\n' "$?"
    fi
    printf '```\n'
}

pathMeta() {
    printf '\n```\n'
    if ! ls -ldZ "$@" 2>&1; then
        printf '(not found)\n'
    fi
    printf '```\n'
}

showFile() {
    topic "File $1"
    if [ ! -e "$1" ]; then
        note 'Not present.'
        return 0
    fi
    pathMeta "$1"
    printf '\n```\n'
    cat "$1" 2>&1 || true
    printf '```\n'
}

secretFile() {
    topic "Secret $1"
    if [ ! -e "$1" ]; then
        note 'Not present.'
        return 0
    fi
    note 'Content not gathered.'
    pathMeta "$1"
}

showTree() {
    topic "Tree $1"
    if [ ! -d "$1" ]; then
        note 'Not present.'
        return 0
    fi
    printf '\n```sh\n$ find %s -maxdepth %s -exec ls -ldZ {} +\n' "$1" "${2:-2}"
    find "$1" -maxdepth "${2:-2}" -exec ls -ldZ {} + 2>&1 || true
    printf '```\n'
}

showFilesOf() {
    for GATHERING_FILE in $1; do
        [ -f "${GATHERING_FILE}" ] || continue
        showFile "${GATHERING_FILE}"
    done
}

serviceState() {
    topic "Service $1"
    runCommand systemctl is-enabled "$1"
    runCommand systemctl is-active "$1"
    runCommand systemctl cat "$1"
}

packageOf() {
    runCommand rpm -q "$@"
}

listeningPorts() {
    runCommand ss -tulpnH
}

selinuxPorts() {
    printf '\n```sh\n$ semanage port -l | grep -E %s\n' "$1"
    semanage port -l 2>&1 | grep -E "$1" || printf '(no match)\n'
    printf '```\n'
}

selinuxBooleans() {
    printf '\n```sh\n$ semanage boolean -l | grep -E %s\n' "$1"
    semanage boolean -l 2>&1 | grep -E "$1" || printf '(no match)\n'
    printf '```\n'
}

selinuxModules() {
    printf '\n```sh\n$ semodule -l | grep -E %s\n' "$1"
    semodule -l 2>&1 | grep -E "$1" || printf '(no match)\n'
    printf '```\n'
}

# The policy rules that decide the label of a path, the local ones added with
# "semanage fcontext -a" included, and what the policy says this exact path should be.
fileContexts() {
    printf '\n```sh\n$ semanage fcontext -l | grep -E %s\n' "$1"
    semanage fcontext -l 2>&1 | grep -E "$1" || printf '(no rule of its own, the parent rule applies)\n'
    printf '```\n'
}

localFileContexts() {
    printf '\n```sh\n$ semanage fcontext -C -l\n'
    semanage fcontext -C -l 2>&1 || true
    printf '```\n'
}

# What the policy would give a path, next to what it has now.
expectedContextOf() {
    printf '\n```sh\n$ matchpathcon %s\n' "$*"
    matchpathcon "$@" 2>&1 || true
    printf '```\n'
}

processContexts() {
    printf '\n```sh\n$ ps -eo user,pid,label,args | grep -E %s\n' "$1"
    ps -eo user,pid,label,args 2>/dev/null | grep -E "$1" | grep -v "grep -E" || printf '(no process)\n'
    printf '```\n'
}

# ==========================================================================
# Checks
# ==========================================================================

# Every file of the tree has the label the policy says it should have. restorecon -n changes
# nothing and prints one line per file whose label differs, which is the answer to "was
# restorecon run after the files were put there".
expectRestoreconClean() {
    topic "Labels of $1 against the policy"
    if [ ! -e "$1" ]; then
        note 'Not present.'
        return 0
    fi
    printf '\n```sh\n$ restorecon -Rvn %s\n' "$1"
    GATHERING_OUTPUT=$(restorecon -Rvn "$1" 2>&1 || true)
    if [ -n "${GATHERING_OUTPUT}" ]; then
        printf '%s\n' "${GATHERING_OUTPUT}"
    else
        printf '(no file differs from the policy)\n'
    fi
    printf '```\n'
    # "Would relabel X from A to B" is a label that differs. Anything else restorecon printed is
    # its own trouble, a path it could not read, which is not a finding about the labels.
    GATHERING_DIFFERING=$(printf '%s' "${GATHERING_OUTPUT}" | grep -i 'relabel' || true)
    GATHERING_UNREADABLE=$(printf '%s' "${GATHERING_OUTPUT}" | grep -iv 'relabel' | grep -v '^$' || true)
    if [ -n "${GATHERING_DIFFERING}" ]; then
        problem "$(printf '%s' "${GATHERING_DIFFERING}" | grep -c .) labels under $1 differ from the policy, restorecon -Rv $1 was not run after the files were put there"
    elif [ -n "${GATHERING_UNREADABLE}" ]; then
        warning "the labels of $1 could not be compared with the policy, run the gathering as root"
    else
        ok "every label of $1 matches the policy"
    fi
}

expectSelinuxType() {
    GATHERING_PATH=$1
    GATHERING_WANTED=$2
    if [ ! -e "${GATHERING_PATH}" ]; then
        note "Not present: ${GATHERING_PATH}"
        return 0
    fi
    GATHERING_TYPE=$(stat -c '%C' "${GATHERING_PATH}" 2>/dev/null | cut -d: -f3)
    if printf '%s' "${GATHERING_WANTED}" | grep -qw "${GATHERING_TYPE:-none}"; then
        ok "${GATHERING_PATH} has SELinux type ${GATHERING_TYPE}"
    else
        problem "${GATHERING_PATH} has SELinux type ${GATHERING_TYPE:-none}, expected one of: ${GATHERING_WANTED}"
    fi
}

# A served tree must not have a type nginx may write to: a compromised web server has to be
# unable to change the pages it serves, let alone a configuration file.
expectNotWritableType() {
    GATHERING_PATH=$1
    if [ ! -e "${GATHERING_PATH}" ]; then
        return 0
    fi
    GATHERING_RW=$(find "${GATHERING_PATH}" -maxdepth 3 -exec stat -c '%C %n' {} + 2>/dev/null \
        | grep -E '^[^ ]*:(httpd_sys_rw_content_t|httpd_sys_script_rw_t|public_content_rw_t):' || true)
    if [ -n "${GATHERING_RW}" ]; then
        printf '\n```\n%s\n```\n' "${GATHERING_RW}"
        problem "${GATHERING_PATH} contains paths with a type the web server may write to, so a compromised nginx can change what it serves"
    else
        ok "nothing under ${GATHERING_PATH} has a web server writable type"
    fi
}

expectOwnerMode() {
    GATHERING_PATH=$1
    GATHERING_OWNER=$2
    GATHERING_MODE=$3
    if [ ! -e "${GATHERING_PATH}" ]; then
        note "Not present: ${GATHERING_PATH}"
        return 0
    fi
    GATHERING_IS=$(stat -c '%U:%G %a' "${GATHERING_PATH}")
    if [ "${GATHERING_IS}" = "${GATHERING_OWNER} ${GATHERING_MODE}" ]; then
        ok "${GATHERING_PATH} is ${GATHERING_IS}"
    else
        problem "${GATHERING_PATH} is ${GATHERING_IS}, expected ${GATHERING_OWNER} ${GATHERING_MODE}"
    fi
}

expectNoGroupOrWorldWrite() {
    GATHERING_PATH=$1
    if [ ! -e "${GATHERING_PATH}" ]; then
        return 0
    fi
    GATHERING_WRITABLE=$(find "${GATHERING_PATH}" -type f \( -perm -0020 -o -perm -0002 \) 2>/dev/null || true)
    if [ -n "${GATHERING_WRITABLE}" ]; then
        printf '\n```\n%s\n```\n' "${GATHERING_WRITABLE}"
        problem "${GATHERING_PATH} has group or world writable files"
    else
        ok "no group or world writable file under ${GATHERING_PATH}"
    fi
}

# The process of a service must run in its own domain. unconfined_service_t means SELinux is not
# confining it at all, whatever the file labels say.
expectProcessType() {
    GATHERING_PATTERN=$1
    GATHERING_WANTED=$2
    GATHERING_LABELS=$(ps -eo label,args 2>/dev/null | grep -E "${GATHERING_PATTERN}" | grep -v 'grep -E' | awk '{ print $1 }' | cut -d: -f3 | sort -u || true)
    if [ -z "${GATHERING_LABELS}" ]; then
        note "No process matches ${GATHERING_PATTERN}."
        return 0
    fi
    for GATHERING_TYPE in ${GATHERING_LABELS}; do
        if printf '%s' "${GATHERING_WANTED}" | grep -qw "${GATHERING_TYPE}"; then
            ok "${GATHERING_PATTERN} runs as ${GATHERING_TYPE}"
        else
            problem "${GATHERING_PATTERN} runs as ${GATHERING_TYPE}, expected one of: ${GATHERING_WANTED}"
        fi
    done
}

expectBoolean() {
    GATHERING_NAME=$1
    GATHERING_WANTED=$2
    GATHERING_STATE=$(getsebool "${GATHERING_NAME}" 2>/dev/null | awk '{ print $3 }' || true)
    if [ -z "${GATHERING_STATE}" ]; then
        note "No such boolean: ${GATHERING_NAME}"
        return 0
    fi
    if [ "${GATHERING_STATE}" = "${GATHERING_WANTED}" ]; then
        ok "boolean ${GATHERING_NAME} is ${GATHERING_STATE}"
    else
        problem "boolean ${GATHERING_NAME} is ${GATHERING_STATE}, expected ${GATHERING_WANTED}"
    fi
}

expectPortType() {
    GATHERING_PORT=$1
    GATHERING_WANTED=$2
    GATHERING_PORTS=$(semanage port -l 2>/dev/null || true)
    if [ -z "${GATHERING_PORTS}" ]; then
        note "Port types not readable, run the gathering as root: tcp ${GATHERING_PORT}"
        return 0
    fi
    GATHERING_LABEL=$(printf '%s\n' "${GATHERING_PORTS}" | awk -v port="${GATHERING_PORT}" '$2 == "tcp" && $0 ~ "(^|[ ,])" port "([ ,]|$)" { print $1 }' | sort -u)
    if [ -z "${GATHERING_LABEL}" ]; then
        warning "tcp port ${GATHERING_PORT} has no SELinux port type, so any confined service that may bind a generic port can take it"
        return 0
    fi
    if printf '%s' "${GATHERING_WANTED}" | grep -qw "${GATHERING_LABEL}"; then
        ok "tcp port ${GATHERING_PORT} is ${GATHERING_LABEL}"
    else
        warning "tcp port ${GATHERING_PORT} is ${GATHERING_LABEL}, expected one of: ${GATHERING_WANTED}"
    fi
}

# One setting of a key value configuration, as the service itself reports it.
expectSetting() {
    GATHERING_WHAT=$1
    GATHERING_IS=$2
    GATHERING_WANTED=$3
    if [ -z "${GATHERING_IS}" ]; then
        note "Not reported: ${GATHERING_WHAT}"
        return 0
    fi
    if [ "${GATHERING_IS}" = "${GATHERING_WANTED}" ]; then
        ok "${GATHERING_WHAT} is ${GATHERING_IS}"
    else
        problem "${GATHERING_WHAT} is ${GATHERING_IS}, expected ${GATHERING_WANTED}"
    fi
}

expectSysctl() {
    GATHERING_KEY=$1
    GATHERING_WANTED=$2
    GATHERING_IS=$(sysctl -n "${GATHERING_KEY}" 2>/dev/null || true)
    if [ -z "${GATHERING_IS}" ]; then
        note "Not readable: ${GATHERING_KEY}"
        return 0
    fi
    if [ "${GATHERING_IS}" = "${GATHERING_WANTED}" ]; then
        ok "${GATHERING_KEY} is ${GATHERING_IS}"
    else
        problem "${GATHERING_KEY} is ${GATHERING_IS}, expected ${GATHERING_WANTED}"
    fi
}
