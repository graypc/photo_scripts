#!/bin/bash

print_error() {
    red='\033[0;31m'
    reset='\033[0m' # No Color
    printf "${red}Error.${reset}  $1\n"
}

print_yellow() {
    yellow='\033[33m'
    reset='\033[0m' # No Color
    printf "${yellow}$1${reset}"
}

get_file_extension() {
    # Get chars trailing '.'
    extension="${1##*.}"

    to_lowercase "$extension"
}

to_lowercase() {
    # Convert to lowercase.
    echo "$1" | tr '[:upper:]' '[:lower:]' 
}

is_jpg() {
    if [ "$1" == "jpg" ]; then
        echo "0"
    elif [ "$1" == "jpeg" ]; then
        echo "0"
    else
        echo "1"
    fi
}

