function findTerminal() {
    if ! command -v xfce-terminal &> /dev/null
    then
        echo "Xfce terminal could not be found"
    else
        xfce-terminal --working-directory=${PWD} &
        exit 0
    fi

    if ! command -v gnome-terminal &> /dev/null
    then
        echo "Gnome terminal could not be found"
    else
        gnome-terminal --working-directory=${PWD} &
        exit 0
    fi

    if ! command -v konsole &> /dev/null
    then
        echo "KDE knosole could not be found"
        exit 1
    else
        konsole --workdir ${PWD} &
        exit 0
    fi
}
