#!/bin/bash
read -p "Enter filename: " file
file="${file:-config.conf}"

if [ -f "$file" ] && [ -r "$file" ] && [ -s "$file" ]; then
    echo "Scanning $file for authentication settings:"
    grep -E 'password|username' "$file"
else
    echo "$file is missing, unreadable, or empty"
    exit 1
fi
