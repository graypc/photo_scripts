#!/bin/bash

print_help() {
    printf "This script prints the exif data for\n"
    printf "a Date/Time Original and Headline attributes\n"
    printf "\t-i <input_directory>.\n"
}

input_dir=""

parse_args() {
    # Parse args.
    while [[ $# -gt 0 ]]; do
        case $1 in
        -h|--help)
            print_help
            exit 0
            ;;
        -i|--input)
            input_dir="$2"
            shift
            shift
            ;;
        *)
            printf "Unknown argument provided\n"
            print_help
            exit 1
            ;;
        esac
    done
}

print_error() {
    red='\033[0;31m'
    reset='\033[0m' # No Color
    printf "${red}Error.${reset}  $1\n"
}

validate_args() {
    if [ -z "$input_dir" ]; then
        printf "Error.  Provide an input directory.\n"
        exit 1
    fi
}

parse_args "$@"
validate_args

printf "Starting with input[%s]\n" "${input_dir}"

# Assuming this is running on a mac.
res=$(dot_clean "$input_dir")
if [ "$?" -ne "0" ]; then
    printf "Error.  Unable to run dot_clean\n"
    exit 1
fi

# Find all the jpeg and png files recursively.
input_photos=$(find "$input_dir" -type f \( -iname "*.jpg" -o -iname "*.mp4" -o -iname "*.png" -o -iname "*.jpeg" \))
if [ "$?" -ne "0" ]; then
    printf "Error.  Unable to find photos\n"
    exit 1
fi

# Split the input into an array.
# Save old IFS
IFS_OLD=$IFS
IFS=$'\n'
input_array=($input_photos)

for photo in "${input_array[@]}"; do
    date_time=$(exiftool -DateTimeOriginal "$photo")
    headline=$(exiftool -Headline "$photo" && res=0 || res=$?)
    printf "Photo[%s] Date[%s] Headline[%s]\n" "${photo}" "${date_time}" "${headline}"
done

exit 0

