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
    codex exec --dangerously-bypass-approvals-and-sandbox "${PROMPT_TEXT}" "$@"
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
    opencode run "${PROMPT_TEXT}" "$@"
}

promptCreator() {
    PROMPT_FILE=${1}
    echo "Read through prepared prompt from ${PROMPT_FILE} as new and newly created"
}

claudeModels() {
    echo "haiku sonnet opus fable"
}

cursorModels() {
    echo "auto gpt-5.3-codex-low gpt-5.3-codex gpt-5.3-codex-high"
}

geminiModels() {
    echo "gemini-2.5-flash gemini-2.5-pro"
}

codexModels() {
    echo "gpt-5.1-codex-mini gpt-5.1-codex gpt-5.1"
}

codewhaleModels() {
    echo "deepseek-chat deepseek-reasoner"
}

opencodeModels() {
    echo "tinker/Qwen/Qwen3-8B tinker/Qwen/Qwen3-30B-A3B tinker/meta-llama/Llama-3.1-70B"
}

claudeOptions() {
    echo "--model ${AGENT_MODEL} --effort ${AGENT_REASONING}"
}

cursorOptions() {
    echo "--model ${AGENT_MODEL}"
}

geminiOptions() {
    echo "--model ${AGENT_MODEL}"
}

codexOptions() {
    echo "--model ${AGENT_MODEL} -c model_reasoning_effort=${AGENT_REASONING}"
}

codewhaleOptions() {
    echo "--model ${AGENT_MODEL}"
}

opencodeOptions() {
    echo "--model ${AGENT_MODEL}"
}

requireAgent() {
    if ! command -v "${1}CLI" >/dev/null 2>&1; then
        echo "ERROR: unknown agent: ${1}" >&2
        exit 1
    fi
}

requirePromptFile() {
    if [ ! -f "${1}" ]; then
        echo "ERROR: prompt file not found: ${1}" >&2
        exit 1
    fi
}

agentCliOptions() {
    AGENT_TYPE=${1}
    shift
    AGENT_MODEL=""
    AGENT_REASONING=low
    while [ $# -gt 0 ]; do
        case "${1}" in
            --model)
                AGENT_MODEL=${2:?--model needs a value}
                shift 2
                ;;
            --reasoning)
                AGENT_REASONING=${2:?--reasoning needs a value}
                shift 2
                ;;
            *)
                echo "ERROR: unknown option: ${1}" >&2
                exit 1
                ;;
        esac
    done
    AGENT_MODELS=$("${AGENT_TYPE}Models")
    if [ -z "${AGENT_MODEL}" ]; then
        AGENT_MODEL=${AGENT_MODELS%% *}
    fi
    case " ${AGENT_MODELS} " in
        *" ${AGENT_MODEL} "*) ;;
        *)
            echo "ERROR: unknown ${AGENT_TYPE} model: ${AGENT_MODEL} (${AGENT_MODELS})" >&2
            exit 1
            ;;
    esac
    case "${AGENT_REASONING}" in
        low|medium|high) ;;
        *)
            echo "ERROR: unknown reasoning: ${AGENT_REASONING} (low medium high)" >&2
            exit 1
            ;;
    esac
    "${AGENT_TYPE}Options"
}
