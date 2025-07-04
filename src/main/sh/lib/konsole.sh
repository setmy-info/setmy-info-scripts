tryToOpenXfceTerminal() {
    COMMAND_NAME=xfce4-terminal
    if ! command -v ${COMMAND_NAME} &> /dev/null
    then
        echo "${COMMAND_NAME} terminal could not be found"
    else
        ${COMMAND_NAME} --title=${COMMAND_NAME} --working-directory=${PWD} --disable-server &
        exit 0
    fi
}

tryToOpenPtyxisTerminal() {
    COMMAND_NAME=ptyxis
    if ! command -v ${COMMAND_NAME} &> /dev/null
    then
        echo "${COMMAND_NAME} terminal could not be found"
    else
       # TODO : --working-directory=${PWD}
        ${COMMAND_NAME} --new-window &
        exit 0
    fi
}

tryToOpenGnomeTerminal() {
    COMMAND_NAME=gnome-terminal
    if ! command -v ${COMMAND_NAME} &> /dev/null
    then
        echo "${COMMAND_NAME} terminal could not be found"
    else
        ${COMMAND_NAME} --working-directory=${PWD} &
        exit 0
    fi
}

tryToOpenMateTerminal() {
    COMMAND_NAME=mate-terminal
    if ! command -v ${COMMAND_NAME} &> /dev/null
    then
        echo "${COMMAND_NAME} terminal could not be found"
    else
        ${COMMAND_NAME} --working-directory=${PWD} &
        exit 0
    fi
}

tryToOpenKonsole() {
    COMMAND_NAME=konsole
    if ! command -v ${COMMAND_NAME} &> /dev/null
    then
        echo "${COMMAND_NAME} terminal could not be found"
    else
        ${COMMAND_NAME} --workdir ${PWD} &
        exit 0
    fi
}

tryToOpenXterm() {
    if ! command -v xterm &> /dev/null
    then
        echo "xterm could not be found"
    else
        xterm -title xterm &
        exit 0
    fi
}

executeTerminal() {
    if [ "$DISPLAY" = ":0.0" ] || [ "$DISPLAY" = ":0" ]
    then
        loadProfiles ${*}
        findTerminal
    else
        term-activate ${*}
    fi
}

findTerminal() {
     tryToOpenXfceTerminal
     tryToOpenGnomeTerminal
     tryToOpenPtyxisTerminal
     tryToOpenMateTerminal
     tryToOpenKonsole
     tryToOpenXterm
}
