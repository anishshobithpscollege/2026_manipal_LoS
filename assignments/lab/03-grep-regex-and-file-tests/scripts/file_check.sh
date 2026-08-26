#!/bin/bash
read -p "Enter filename: " file

echo ""
echo "----- FILE INVESTIGATION -----"
echo ""

if [ -e "$file" ]; then exists="Yes"; else exists="No"; fi
if [ -f "$file" ]; then regular="Yes"; else regular="No"; fi
if [ -d "$file" ]; then directory="Yes"; else directory="No"; fi

if [ -r "$file" ]; then readable="Yes"; else readable="No"; fi
if [ -w "$file" ]; then writable="Yes"; else writable="No"; fi
if [ -x "$file" ]; then executable="Yes"; else executable="No"; fi

if [ -s "$file" ]; then nonempty="Yes"; else nonempty="No"; fi

if [[ "$file" =~ \.sh$ ]]; then shell="Yes"; else shell="No"; fi

printf "Exists        : %s\n" "$exists"
printf "Regular File  : %s\n" "$regular"
printf "Directory     : %s\n" "$directory"
printf "Readable      : %s\n" "$readable"
printf "Writable      : %s\n" "$writable"
printf "Executable    : %s\n" "$executable"
printf "Non-empty     : %s\n" "$nonempty"
printf "Shell Script  : %s\n" "$shell"
echo ""

wget_result="Skipped"
indicators_result="Skipped"

if [ "$readable" = "Yes" ] && [ "$nonempty" = "Yes" ]; then
    grep -q wget "$file"
    if [ $? -eq 0 ]; then wget_result="Found"; else wget_result="Not found"; fi

    grep -E -q 'wget|curl|nc|chmod' "$file"
    if [ $? -eq 0 ]; then indicators_result="Found"; else indicators_result="Not found"; fi
fi

printf "wget          : %s\n" "$wget_result"
printf "Selected indicators : %s\n" "$indicators_result"
echo ""

if [ "$wget_result" = "Found" ] || [ "$indicators_result" = "Found" ]; then
    echo "Further inspection recommended"
else
    echo "No selected indicators found"
fi
