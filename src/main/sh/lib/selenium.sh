# https://www.selenium.dev/documentation/grid/getting_started/

runSeleniumHub() {
    java -jar $(smi-lib-location)/${SELENIUM_JAR_FILE_NAME} hub
}

runSeleniumNode() {
    HUB_URL=${1}
    java -jar $(smi-lib-location)/${SELENIUM_JAR_FILE_NAME} node --hub ${HUB_URL}
}

runSeleniumStandalone() {
    HUB_URL=${1}
    java -jar $(smi-lib-location)/${SELENIUM_JAR_FILE_NAME} standalone
}
