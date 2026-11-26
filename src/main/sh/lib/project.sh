PROJECT_STAGE=

projectName() {
    basename "${PWD}"
}

projectRunStage() {
    PROJECT_STAGE="$1"
    if command -v "$2" >/dev/null 2>&1; then
        "$2"
    fi
}

projectStep() {
    echo "${PROJECT_STAGE:+${PROJECT_STAGE}: }$1"
    "$@"
}

projectEditFile() {
    project_file="$1"
    shift
    [ -f "${project_file}" ] || return 0
    "$@" < "${project_file}" > "${project_file}.smi-tmp"
    cat "${project_file}.smi-tmp" > "${project_file}"
    rm -f "${project_file}.smi-tmp"
}

projectRemove() {
    rm -rf "$@"
}

projectRemoveExcept() {
    project_keep="$1"
    shift
    for project_path in "$@"; do
        [ "$(basename "${project_path}")" = "${project_keep}" ] || rm -rf "${project_path}"
    done
}

projectRemoveEmptyFile() {
    [ -s "$1" ] || rm -f "$1"
}

projectRename() {
    [ -e "$1" ] || return 0
    mv "$1" "$2"
}

projectReplaceInFile() {
    projectEditFile "$1" sed -e "s|$2|$3|g"
}

projectDeleteLinesInFile() {
    project_file="$1"
    shift
    for project_pattern in "$@"; do
        projectEditFile "${project_file}" sed -e "\|${project_pattern}|d"
    done
}

projectRemoveMavenModulesWithoutFolder() {
    projectEditFile "$1/pom.xml" awk -v base="$1" '
        match($0, /<module>[^<]*<\/module>/) {
            m = substr($0, RSTART + 8, RLENGTH - 17)
            if (system("test -d \"" base "/" m "\"") != 0) next
        }
        { print }'
}

projectRemoveGitSubmodulesWithoutFolder() {
    projectEditFile .gitmodules awk '
        function flush() { if (!drop) printf "%s", buf; buf = ""; drop = 0 }
        /^\[submodule / { flush() }
        /^[ \t]*path[ \t]*=/ {
            path = $0
            sub(/^[ \t]*path[ \t]*=[ \t]*/, "", path)
            if (system("test -e \"" path "\"") != 0) drop = 1
        }
        { buf = buf $0 "\n" }
        END { flush() }'
    projectRemoveEmptyFile .gitmodules
}
