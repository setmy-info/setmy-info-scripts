export CLAUDE_BIN_DIR=~/.local/bin
case ":${PATH}:" in
    *:"${CLAUDE_BIN_DIR}":*) ;;
    *) export PATH=${CLAUDE_BIN_DIR}:${PATH} ;;
esac
