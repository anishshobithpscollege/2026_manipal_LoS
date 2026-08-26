#!/bin/bash
read -p "Enter filename: " file

if [ ! -e "$file" ]; then
    echo "$file does not exist"
    exit 1
fi

if [ ! -f "$file" ]; then
    echo "$file is not a regular file"
    exit 1
fi

if [ ! -r "$file" ]; then
    echo "$file is not readable"
    exit 1
fi

if [ ! -s "$file" ]; then
    echo "$file is empty"
    exit 1
fi

if grep -q wget "$file"; then
    echo "Selected indicator detected, investigate further"
else
    echo "Selected indicator not detected"
fi
