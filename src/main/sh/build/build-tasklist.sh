#!/bin/sh

# ./src/main/sh/build/build-tasklist.sh in root folder

cat src/main/resources/tasklist/AGENTS-INTRO.md > TASKLIST.md
ai setmy-info-scripts cmake groovy git cleancode bottom-up >> TASKLIST.md
echo "" >> TASKLIST.md
echo "## Tasklist" >> TASKLIST.md
echo "" >> TASKLIST.md
# TODO: parameter instad TASKLIST-CONTENT.md
cat TASKLIST-CONTENT.md >> TASKLIST.md

exit 0
