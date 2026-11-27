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

projectRemoveEmptyFolders() {
    for project_folder in "$@"; do
        [ -d "${project_folder}" ] && rmdir "${project_folder}" 2>/dev/null || :
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

projectReplaceWordInFile() {
    projectEditFile "$1" awk -v from="$2" -v to="$3" '
        function isWordChar(c) { return c ~ /[A-Za-z0-9_-]/ }
        {
            out = ""
            rest = $0
            while ((i = index(rest, from)) > 0) {
                before = i > 1 ? substr(rest, i - 1, 1) : substr(out, length(out), 1)
                after = substr(rest, i + length(from), 1)
                if (!isWordChar(before) && !isWordChar(after)) {
                    out = out substr(rest, 1, i - 1) to
                } else {
                    out = out substr(rest, 1, i - 1 + length(from))
                }
                rest = substr(rest, i + length(from))
            }
            print out rest
        }'
}

projectRemoveXmlElement() {
    projectEditFile "$1" awk -v tag="$2" -v text="${3:-}" '
        function flush() { if (!(text == "" || index(buf, text) > 0)) printf "%s", buf; buf = ""; inside = 0 }
        !inside && $0 ~ "^[ \t]*<" tag "([ >]|$)" { inside = 1 }
        inside { buf = buf $0 "\n"; if ($0 ~ "</" tag ">") flush(); next }
        { print }
        END { if (inside) printf "%s", buf }'
}

projectWriteFile() {
    printf '%s\n' "$2" > "$1"
}

projectDeleteLinesInFile() {
    project_file="$1"
    shift
    for project_pattern in "$@"; do
        projectEditFile "${project_file}" sed -e "\|${project_pattern}|d"
    done
}

projectRemoveParagraphsInFile() {
    project_file="$1"
    shift
    for project_first in "$@"; do
        projectEditFile "${project_file}" awk -v first="${project_first}" '
            skip && /^[ \t]*$/ { skip = 0; next }
            skip { next }
            $0 == first { skip = 1; next }
            { print }'
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

projectRemoveMavenModulesExcept() {
    project_base="$1"
    shift
    for project_module in $(sed -n 's|.*<module>\([^<]*\)</module>.*|\1|p' "${project_base}/pom.xml"); do
        case " $* " in
            *" ${project_module} "*) ;;
            *)
                rm -rf "${project_base:?}/${project_module}"
                projectDeleteLinesInFile "${project_base}/pom.xml" "<module>${project_module}</module>"
                ;;
        esac
    done
}

projectRenameMavenArtifact() {
    project_from="$1"
    project_to="$2"
    shift 2
    for project_pom in "$@"; do
        projectReplaceInFile "${project_pom}" "<artifactId>${project_from}</artifactId>" "<artifactId>${project_to}</artifactId>"
        projectReplaceInFile "${project_pom}" "<name>${project_from}</name>" "<name>${project_to}</name>"
    done
}

projectRemoveGitignoreEntriesWithoutFolder() {
    projectEditFile "${1:-.gitignore}" awk '
        function emit(text) {
            if (text == "") { if (!lastBlank) print ""; lastBlank = 1 }
            else { printf "%s", text; lastBlank = 0 }
        }
        function flush() {
            if (buf != "" && !(dropped > 0 && kept == 0)) emit(buf)
            buf = ""; kept = 0; dropped = 0
        }
        function folderMissing(line,    first) {
            first = line
            sub(/^\//, "", first)
            if (first !~ /^[A-Za-z0-9._-]+\/./) return 0
            sub(/\/.*/, "", first)
            return system("test -e \"" first "\"") != 0
        }
        /^[ \t]*$/ { flush(); emit(""); next }
        /^[ \t]*[#!]/ { buf = buf $0 "\n"; next }
        folderMissing($0) { dropped++; next }
        { kept++; buf = buf $0 "\n" }
        END { flush() }'
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
