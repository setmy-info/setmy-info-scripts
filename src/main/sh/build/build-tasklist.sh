#!/bin/sh

# Copyright (C) 2026 Imre Tabur <imre.tabur@mail.ee>
# Usage: ./src/main/sh/build/build-tasklist.sh [file1.md file2.md ...]
# If no files given, defaults to TASKLIST-CONTENT.md

cat src/main/resources/tasklist/AGENTS-INTRO.md > TASKLIST.md
ai setmy-info-scripts cmake groovy git cleancode bottom-up fhs >> TASKLIST.md
echo "" >> TASKLIST.md
echo "## Tasklist" >> TASKLIST.md
echo "" >> TASKLIST.md

if [ $# -eq 0 ]; then
    cat TASKLIST-CONTENT.md >> TASKLIST.md
else
    for FILE in "$@"; do
        cat "${FILE}" >> TASKLIST.md
    done
fi

exit 0
