#!/bin/sh

print_help() {
    # "Date/Time Original              : 2021:05:06 17:32:59"
    printf "This script uses exiftool to encode an Date/Time Original attribute\n"
    printf "to all photos in the supplied directory.  Provide the path the the"
    printf "directory and a date string.  The time is set to 12:00:00 for simplicity."
    printf "Two inputs are required\n"
    printf "\t-i <input_directory>.  Subdirectories are not allowed.\n"
    printf "\t-d <date>.  Example '2021:05:06'.\n"
}

input_dir=""
date_original=""

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
        -d|--date_original)
            date_original="$2"
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
    
    if [ -z "$date_original" ]; then
        printf "Error.  Provide an orignal date.\n"
        exit 1
    fi

    res=$(echo "$date_original" | grep -o -E "[0-9][0-9][0-9][0-9]:[0-9][0-9]:[0-9][0-9]")
    if [ "$?" -ne "0" ]; then
        print_error "Invalid date provided."
        print_help
        exit 1
    fi
    date_original="$date_original 12:00:00"
}

parse_args "$@"
validate_args

printf "Starting with input[%s] date[%s]\n" "$input_dir" "$date_original"

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
    result="Processing"

    res=$(exiftool -overwrite_original -DateTimeOriginal="$date_original" "$photo")
    if [ "$?" -ne "0" ]; then
        printf "%s\n" "$result"
        print_error "Unable to set original date"
        continue
    fi
done

exit 0

