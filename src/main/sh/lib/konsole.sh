tryToOpenXfceTerminal() {
    COMMAND_NAME=xfce4-terminal
    if ! command -v ${COMMAND_NAME} &> /dev/null
    then
        echo "${COMMAND_NAME} terminal could not be found"
    else
        exec ${COMMAND_NAME} --title=${COMMAND_NAME} --working-directory=${PWD} --disable-server
    fi
}

tryToOpenPtyxisTerminal() {
    COMMAND_NAME=ptyxis
    if ! command -v ${COMMAND_NAME} &> /dev/null
    then
        echo "${COMMAND_NAME} terminal could not be found"
    else
       # TODO : --working-directory=${PWD}
        exec ${COMMAND_NAME} --new-window
    fi
}

tryToOpenGnomeTerminal() {
    COMMAND_NAME=gnome-terminal
    if ! command -v ${COMMAND_NAME} &> /dev/null
    then
        echo "${COMMAND_NAME} terminal could not be found"
    else
        exec ${COMMAND_NAME} --working-directory=${PWD}
    fi
}

tryToOpenMateTerminal() {
    COMMAND_NAME=mate-terminal
    if ! command -v ${COMMAND_NAME} &> /dev/null
    then
        echo "${COMMAND_NAME} terminal could not be found"
    else
        exec ${COMMAND_NAME} --working-directory=${PWD}
    fi
}

tryToOpenKonsole() {
    COMMAND_NAME=konsole
    if ! command -v ${COMMAND_NAME} &> /dev/null
    then
        echo "${COMMAND_NAME} terminal could not be found"
    else
        exec ${COMMAND_NAME} --workdir ${PWD}
    fi
}

tryToOpenXterm() {
    if ! command -v xterm &> /dev/null
    then
        echo "xterm could not be found"
    else
        exec xterm -title xterm
    fi
}

executeTerminal() {
    if [ -n "${DISPLAY}" ] || [ -n "${WAYLAND_DISPLAY}" ]
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
