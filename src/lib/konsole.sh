function tryToOpenTerminal() {
    COMMAND_NAME=${1}
    if ! command -v ${COMMAND_NAME} &> /dev/null
    then
        echo "${COMMAND_NAME} terminal could not be found"
    else
        ${COMMAND_NAME} --working-directory=${PWD} --title=${COMMAND_NAME} &
        exit 0
    fi
}

function tryToOpenKonsole() {
    COMMAND_NAME=konsole
    if ! command -v ${COMMAND_NAME} &> /dev/null
    then
        echo "${COMMAND_NAME} terminal could not be found"
    else
        ${COMMAND_NAME} --workdir ${PWD} &
        exit 0
    fi
}

function tryToOpenXterm() {
    if ! command -v xterm &> /dev/null
    then
        echo "xterm could not be found"
    else
        xterm -title xterm &
        exit 0
    fi
}

function findTerminal() {
     tryToOpenTerminal xfce4-terminal
     tryToOpenTerminal xfce-terminal
     tryToOpenTerminal gnome-terminal
     tryToOpenKonsole
     tryToOpenXterm
}
