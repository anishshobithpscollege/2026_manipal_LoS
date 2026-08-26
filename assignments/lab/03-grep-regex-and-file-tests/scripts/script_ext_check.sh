#!/bin/bash
read -p "Enter filename: " file

if [[ "$file" =~ \.(sh|py|pl)$ ]]; then
    echo "Script file, inspect if required"
else
    echo "Not a recognised script file"
fi
