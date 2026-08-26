#!/bin/bash
read -p "Enter filename: " file

if [ -f "$file" ] && [ -r "$file" ] && [ -s "$file" ]; then
    if grep -E -q 'wget|curl|nc|chmod' "$file"; then
        echo "One or more selected indicators detected"
    else
        echo "Selected indicators not detected"
    fi
else
    echo "$file failed the pre-checks (regular, readable, non-empty)"
    exit 1
fi
