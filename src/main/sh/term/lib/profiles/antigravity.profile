export ANTIGRAVITY_BIN_DIR=~/.local/bin
case ":${PATH}:" in
    *:"${ANTIGRAVITY_BIN_DIR}":*) ;;
    *) export PATH=${ANTIGRAVITY_BIN_DIR}:${PATH} ;;
esac
