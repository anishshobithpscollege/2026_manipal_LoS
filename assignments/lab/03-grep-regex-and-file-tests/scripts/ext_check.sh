#!/bin/bash
read -p "Enter filename: " file

if [[ "$file" =~ \.sh$ ]]; then
    echo "Shell script identified for inspection"
else
    echo "File does not have a .sh extension"
fi
