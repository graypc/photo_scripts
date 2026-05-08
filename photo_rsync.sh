#!/bin/sh

print_help() {
    printf "This script uses rsync to merge two directories of photos.\n"
    printf "Both directories should be previously sorted with MetaSort\n"
    printf "or photo_date_marshaller.sh."
    printf "Two inputs are required\n"
    printf "\t-i <input_directory>.\n"
    printf "\t-o <output_directory>.\n"
}

input_dir=""
output_dir=""

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
        -o|--output)
            output_dir="$2"
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
    
    if [ -z "$output_dir" ]; then
        printf "Error.  Provide an output directory.\n"
        exit 1
    fi
}

print_error() {
    red='\033[0;31m'
    reset='\033[0m' # No Color
    printf "${red}Error.${reset}  $1\n"
}

parse_args "$@"
validate_args

printf "Starting with input[%s] output[%s]\n" "$input_dir" "$output_dir"

rsync -av --exclude="._*" --exclude="*.DS_Store*" "$input_dir" "$output_dir"

