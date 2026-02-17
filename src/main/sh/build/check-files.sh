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

FAILED=0

# Check bin directory
check_directory "$CHECK_DIR/bin" 85 || FAILED=1

# Check lib directory
check_directory "$CHECK_DIR/lib" 161 || FAILED=1

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

if [ $FAILED -ne 0 ]; then
    echo "Verification FAILED"
    exit 1
fi

echo "Verification SUCCESSFUL"
exit 0
