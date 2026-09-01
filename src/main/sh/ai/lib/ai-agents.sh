claudeCLI() {
    PROMPT_FILE=${1}
    shift
    PROMPT_TEXT=$(promptCreator "${PROMPT_FILE}")
    claude -p "${PROMPT_TEXT}" --dangerously-skip-permissions "$@"
}

cursorCLI() {
    PROMPT_FILE=${1}
    shift
    PROMPT_TEXT=$(promptCreator "${PROMPT_FILE}")
    cursor-agent -p --force "${PROMPT_TEXT}" "$@"
}

geminiCLI() {
    PROMPT_FILE=${1}
    shift
    PROMPT_TEXT=$(promptCreator "${PROMPT_FILE}")
    gemini -p "${PROMPT_TEXT}" --yolo "$@"
}

codexCLI() {
    PROMPT_FILE=${1}
    shift
    PROMPT_TEXT=$(promptCreator "${PROMPT_FILE}")
    codex exec --full-auto "${PROMPT_TEXT}" "$@"
}

codewhaleCLI() {
    PROMPT_FILE=${1}
    shift
    PROMPT_TEXT=$(promptCreator "${PROMPT_FILE}")
    codewhale exec --auto --output-format stream-json "${PROMPT_TEXT}" "$@"
}

opencodeCLI() {
    PROMPT_FILE=${1}
    shift
    PROMPT_TEXT=$(promptCreator "${PROMPT_FILE}")
    opencode run --auto "${PROMPT_TEXT}" "$@"
}

promptCreator() {
    PROMPT_FILE=${1}
    echo "Read through prepared prompt from ${PROMPT_FILE} as new and newly created"
}