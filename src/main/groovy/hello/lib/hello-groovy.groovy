final int MIN_EXIT_CODE = 0
final int MAX_EXIT_CODE = 255
final int INVALID_EXIT_CODE = 1

int parseExitCode(List<String> arguments, int min, int max, int invalid) {
    if (arguments.isEmpty()) {
        return min
    }
    try {
        int value = Integer.parseInt(arguments[0])
        return (value >= min && value <= max) ? value : invalid
    } catch (NumberFormatException ignored) {
        return invalid
    }
}

int printExitCode(int exitCode) {
    if (exitCode != 0) {
        println "Exiting with code ${exitCode}."
    }
    return exitCode
}

println "Hello, world from ${new File('.').canonicalPath} as UUID: ${UUID.randomUUID()}!"

System.exit(printExitCode(parseExitCode(args as List, MIN_EXIT_CODE, MAX_EXIT_CODE, INVALID_EXIT_CODE)))
