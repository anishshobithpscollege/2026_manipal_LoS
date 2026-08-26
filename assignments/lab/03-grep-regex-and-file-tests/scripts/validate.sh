#!/bin/bash
read -p "Enter filename: " file

if [ -e "$file" ]; then echo "Exists       : Yes"; else echo "Exists       : No"; fi
if [ -f "$file" ]; then echo "Regular File : Yes"; else echo "Regular File : No"; fi
if [ -r "$file" ]; then echo "Readable     : Yes"; else echo "Readable     : No"; fi
if [ -s "$file" ]; then echo "Non-empty    : Yes"; else echo "Non-empty    : No"; fi
