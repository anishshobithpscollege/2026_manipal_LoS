#!/bin/bash

echo "Enter the name of the tool:"
read tool

if command -v $tool > /dev/null
then
    echo "$tool is installed."
else
    echo "$tool is not installed."
fi
