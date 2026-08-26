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

if [ ! -x "$file" ]; then
    echo "$file is not executable"
    exit 1
fi

if grep -q wget "$file"; then
    echo "wget found in executable file $file"
else
    echo "wget not found in $file"
fi
