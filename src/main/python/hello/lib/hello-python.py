import os
import sys
import uuid

MIN_EXIT_CODE = 0
MAX_EXIT_CODE = 255
INVALID_EXIT_CODE = 1


def parse_exit_code(arguments):
    if not arguments:
        return MIN_EXIT_CODE
    try:
        value = int(arguments[0])
    except ValueError:
        return INVALID_EXIT_CODE
    return value if MIN_EXIT_CODE <= value <= MAX_EXIT_CODE else INVALID_EXIT_CODE


def print_exit_code(exit_code):
    if exit_code != 0:
        print(f"Exiting with code {exit_code}.")
    return exit_code


print(f"Hello, world from {os.getcwd()} as UUID: {uuid.uuid4()}!")

sys.exit(print_exit_code(parse_exit_code(sys.argv[1:])))
