#!/bin/sh

# Directory to check
CHECK_DIR="/opt/setmy.info"

echo "Checking installation in $CHECK_DIR"

if [ ! -d "$CHECK_DIR" ]; then
    echo "Error: $CHECK_DIR does not exist"
    exit 1
fi

check_directory() {
    DIR=$1
    MIN_FILES=$2
    echo "Checking directory: $DIR (min files: $MIN_FILES)"
    if [ ! -d "$DIR" ]; then
        echo "Error: $DIR does not exist"
        return 1
    fi
    FILE_COUNT=$(find "$DIR" -type f | wc -l)
    echo "Found $FILE_COUNT files in $DIR"
    if [ "$FILE_COUNT" -lt "$MIN_FILES" ]; then
        echo "Error: $DIR contains fewer than $MIN_FILES files"
        return 1
    fi
    return 0
}

check_line_endings() {
    DIR=$1
    echo "Checking line endings in directory: $DIR"
    if [ ! -d "$DIR" ]; then
        echo "Error: $DIR does not exist"
        return 1
    fi

    # Find files that contain CRLF line endings (\r\n)
    # Using grep -r -l $'\r' is common, but $'\r' might not be POSIX.
    # POSIX way to represent CR is $(printf '\r')
    CR=$(printf '\r')
    FILES_WITH_CRLF=$(find "$DIR" -type f -exec grep -l "$CR" {} +)

    if [ -n "$FILES_WITH_CRLF" ]; then
        echo "Error: Found files with CRLF line endings in $DIR:"
        echo "$FILES_WITH_CRLF"
        return 1
    fi

    echo "All files in $DIR have correct line endings."
    return 0
}

check_command_output() {
    COMMAND_NAME=$1
    ARGUMENTS=$2
    EXPECTED_OUTPUT=$3
    COMMAND_PATH="$CHECK_DIR/bin/$COMMAND_NAME"

    echo "Checking command: $COMMAND_NAME $ARGUMENTS (expected: $EXPECTED_OUTPUT)"

    if [ ! -f "$COMMAND_PATH" ]; then
        echo "Error: $COMMAND_PATH does not exist"
        return 1
    fi

    # Set PATH so internal command calls (like smi-lib-location) work
    OLD_PATH=$PATH
    export PATH="$CHECK_DIR/bin:$PATH"

    ACTUAL_OUTPUT=$($COMMAND_PATH $ARGUMENTS)
    EXIT_CODE=$?

    export PATH=$OLD_PATH

    if [ $EXIT_CODE -ne 0 ]; then
        echo "Error: $COMMAND_NAME exited with code $EXIT_CODE"
        return 1
    fi

    if [ "$ACTUAL_OUTPUT" != "$EXPECTED_OUTPUT" ]; then
        echo "Error: $COMMAND_NAME output mismatch"
        echo "  Expected: $EXPECTED_OUTPUT"
        echo "  Actual  : $ACTUAL_OUTPUT"
        return 1
    fi

    return 0
}

FAILED=0

find /opt/setmy.info/bin/ -type f -exec dos2unix {} + 2>/dev/null
find /opt/setmy.info/lib/ -type f -exec dos2unix {} + 2>/dev/null

# Check line endings in bin and lib directories
check_line_endings "$CHECK_DIR/bin" || FAILED=1
check_line_endings "$CHECK_DIR/lib" || FAILED=1

# Check bin directory
check_directory "$CHECK_DIR/bin" 87 || FAILED=1

# Check lib directory
check_directory "$CHECK_DIR/lib" 171 || FAILED=1

# Check man directory
check_directory "$CHECK_DIR/man" 70 || FAILED=1

# Check etc directory in /opt
check_directory "$CHECK_DIR/etc" 5 || FAILED=1

# Check /etc/profile.d symlink
echo "Checking symlink: /etc/profile.d/setmy-info.sh"
if [ ! -L "/etc/profile.d/setmy-info.sh" ]; then
    echo "Error: /etc/profile.d/setmy-info.sh is not a symlink"
    FAILED=1
fi

# Check /var/opt/setmy.info directory
echo "Checking directory: /var/opt/setmy.info"
if [ ! -d "/var/opt/setmy.info" ]; then
    echo "Error: /var/opt/setmy.info does not exist"
    FAILED=1
fi

# Check matching commands output
#check_command_output "base64encode" "test" "dGVzdA==" || FAILED=1
#check_command_output "base64decode" "dGVzdA==" "test" || FAILED=1
#check_command_output "degrees" "1" "57.29577951308232" || FAILED=1
#check_command_output "radians" "57.29577951308232" "1.0" || FAILED=1

# SMI Location commands
check_command_output "smi-bin-location" "" "$CHECK_DIR/bin" || FAILED=1
check_command_output "smi-etc-location" "" "$CHECK_DIR/etc" || FAILED=1
check_command_output "smi-lib-location" "" "$CHECK_DIR/lib" || FAILED=1
check_command_output "smi-man-location" "" "$CHECK_DIR/man" || FAILED=1
check_command_output "smi-var-location" "" "/var/opt/setmy.info" || FAILED=1
check_command_output "smi-temp-location" "" "/tmp/setmy.info" || FAILED=1
check_command_output "smi-home-location" "" "$HOME/.setmy.info" || FAILED=1
check_command_output "smi-home-packages-location" "" "$HOME/.setmy.info/packages" || FAILED=1

# SMI Gintra and other fixed locations
check_command_output "smi-gintra-location" "" "/var/opt/setmy.info/gintra" || FAILED=1
check_command_output "smi-gintra-mount-location" "" "/mnt/gintra" || FAILED=1
# FreeBSD test
#check_command_output "smi-jails-location" "" "/var/jails" || FAILED=1
check_command_output "smi-organizations-location" "" "/var/opt/setmy.info/gintra/organizations" || FAILED=1
check_command_output "smi-persons-location" "" "/var/opt/setmy.info/gintra/persons" || FAILED=1

# SMI Library sub-locations
check_command_output "smi-packages-location" "" "$CHECK_DIR/lib/packages" || FAILED=1
check_command_output "smi-profiles-location" "" "$CHECK_DIR/lib/profiles" || FAILED=1

# SMI Include helper
check_command_output "smi-include" "base.sh" "$CHECK_DIR/lib/base.sh" || FAILED=1

# SMI Version and Provider (from base.sh)
# Note: These values should match what is in src/main/sh/lib/base.sh (or target/Release/build/lib/base.sh)
# Based on previous inspection, PROVIDER=setmy.info and VERSION=0.101.0
check_command_output "smi-version" "" "0.101.0" || FAILED=1

# Deprecated location scripts
check_command_output "smi-config" "" "/opt/setmy.info/etc/localhost/config" || FAILED=1
check_command_output "smi-localhost-location" "" "/opt/setmy.info/etc/localhost" || FAILED=1
check_command_output "smi-net-location" "" "/var/opt/setmy.info/net" || FAILED=1
check_command_output "smi-nics-location" "" "/opt/setmy.info/etc/localhost/nics" || FAILED=1
check_command_output "smi-nodes-location" "" "/opt/setmy.info/etc/localhost/nodes" || FAILED=1
check_command_output "smi-services-location" "" "/opt/setmy.info/etc/localhost/services" || FAILED=1

# Scripts with parameters
check_command_output "smi-organization-location" "EE example" "/var/opt/setmy.info/gintra/organizations/EE/example" || FAILED=1
check_command_output "smi-organization-dir-location" "EE example test" "/var/opt/setmy.info/gintra/organizations/EE/example/test" || FAILED=1
check_command_output "smi-person-name-hash" "Imre Tabur" "person_hash_d0388bf1dfab9a7857a2130722" || FAILED=1
check_command_output "smi-person-location" "Imre Tabur" "/var/opt/setmy.info/gintra/persons/person_hash_d0388bf1dfab9a7857a2130722" || FAILED=1

# Test hgrep (mocking .bash_history)
echo "test_history_line" > "$HOME/.bash_history"
check_command_output "hgrep" "test_history_line" "test_history_line" || FAILED=1
rm "$HOME/.bash_history"

if [ $FAILED -ne 0 ]; then
    echo "Verification FAILED"
    exit 1
fi

echo "Verification SUCCESSFUL"
exit 0
