#!/bin/bash
read -p "Enter filename: " file

if [ -s "$file" ]; then
    echo "File contains data"
else
    echo "File is empty"
fi
