#!/bin/sh

# ./src/main/sh/build/build-tasklist.sh in root folder

TASKLIST_CONTENT=${1:-TASKLIST-CONTENT.md}

cat src/main/resources/tasklist/AGENTS-INTRO.md > TASKLIST.md
ai setmy-info-scripts cmake groovy git cleancode bottom-up fhs >> TASKLIST.md
echo "" >> TASKLIST.md
echo "## Tasklist" >> TASKLIST.md
echo "" >> TASKLIST.md

if [ -f "src/main/resources/tasklist/${TASKLIST_CONTENT}" ]; then
  cat "src/main/resources/tasklist/${TASKLIST_CONTENT}" >> TASKLIST.md
else
  cat src/main/resources/tasklist/0-AI-BUILD-SCRIPT.md >> TASKLIST.md
  cat src/main/resources/tasklist/1-UPDATE-PROFILES.md >> TASKLIST.md
  cat src/main/resources/tasklist/2-FIX-VERSIONS-SPIDER.md >> TASKLIST.md
  cat src/main/resources/tasklist/3-AI-BUILD-SCRIPT.md >> TASKLIST.md
fi

exit 0
