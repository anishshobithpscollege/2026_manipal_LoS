#!/bin/bash
read -p "Enter filename: " file

echo "File: $file"
echo ""

if [ -r "$file" ]; then readable="Yes"; else readable="No"; fi
if [ -w "$file" ]; then writable="Yes"; else writable="No"; fi
if [ -x "$file" ]; then executable="Yes"; else executable="No"; fi

printf "Readable   : %s\n" "$readable"
printf "Writable   : %s\n" "$writable"
printf "Executable : %s\n" "$executable"
