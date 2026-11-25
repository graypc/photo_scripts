#!/bin/sh

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source "$script_dir/common.sh"

print_help() {
    printf "This script uses exiftool to encode a Headline attribute\n"
    printf "to all photos in the supplied directory.  Provide the path the the"
    printf "directory and a Headline."
    printf "Two inputs are required\n"
    printf "\t-i <input_directory>.  Subdirectories are not allowed.\n"
    printf "\t-t <headline>.  Example 'Elliot school'.\n"
}

input_dir=""
headline=""

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
        -t|--headline)
            headline="$2"
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

validate_args() {
    if [ -z "$input_dir" ]; then
        printf "Error.  Provide an input directory.\n"
        exit 1
    fi
    
    if [ -z "$headline" ]; then
        printf "Error.  Provide a headline.\n"
        exit 1
    fi
}

parse_args "$@"
validate_args

printf "Starting with input[%s] headline[%s]\n" "$input_dir" "$headline"

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
    result="Processing $photo"

    res=$(exiftool -overwrite_original -Headline="$headline" "$photo")
    if [ "$?" -ne "0" ]; then
        printf "%s\n" "$result"
        print_error "$result. Unable to set headline"
        continue
    fi
    printf "%s OK\n" "$result"
done

exit 0

