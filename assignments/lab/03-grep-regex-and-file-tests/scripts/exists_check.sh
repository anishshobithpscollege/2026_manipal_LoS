#!/bin/bash
read -p "Enter filename: " file

if [ -e "$file" ]; then
    echo "$file exists"
else
    echo "$file does not exist"
fi
