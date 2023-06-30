function tryToOpenXfceTerminal() {
     COMMAND_NAME=xfce4-terminal
    if ! command -v ${COMMAND_NAME} &> /dev/null
    then
        echo "${COMMAND_NAME} terminal could not be found"
    else
        ${COMMAND_NAME} --title=${COMMAND_NAME} --working-directory=${PWD} --disable-server &
        exit 0
    fi
}

function tryToOpenGnomeTerminal() {
    COMMAND_NAME=gnome-terminal
    if ! command -v ${COMMAND_NAME} &> /dev/null
    then
        echo "${COMMAND_NAME} terminal could not be found"
    else
        ${COMMAND_NAME} --working-directory=${PWD} &
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
     tryToOpenXfceTerminal
     tryToOpenGnomeTerminal
     tryToOpenKonsole
     tryToOpenXterm
}