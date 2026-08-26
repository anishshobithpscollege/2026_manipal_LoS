#!/bin/bash
read -p "Enter filename: " file

if [ -f "$file" ]; then
    echo "$file is a regular file"
elif [ -d "$file" ]; then
    echo "$file is a directory"
else
    echo "$file is neither a regular file nor a directory"
fi
