#!/bin/sh

# ./src/main/sh/build/build-tasklist.sh in root folder

cat AGENTS-INTO.md > TASKLIST.md \
&& ai setmy-info-scripts cmake groovy git cleancode bottom-up >> TASKLIST.md \
&& cat TASKLIST-CONTENT.md >> TASKLIST.md

exit 0
