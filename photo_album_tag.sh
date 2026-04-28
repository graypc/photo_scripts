#!/bin/sh

# Add a searchable caption to the image.
exiftool -Description='my_work' -overwrite_original infinite_harvest.jpg

print_help() {
    printf "This script uses exiftool to sort a directly of photos by year and month.\n"
    printf "The output directory structure is intended to mimic MetaSort which uses \n"
    printf "google takeout json metadata to determine the photo's original creation date/time.\n"
    printf "\thttps://github.com/iamsanmith/MetaSort\n"
    printf "Input photos to this script do not have associated metadata files so MetaSort\n"
    printf "cannot process them.\n"
    printf "If creation date/time is not availalbe in the exif the photo is moved to an\n"
    printf "\"unknown\" directory.\n"
    printf "Two inputs are required\n"
    printf "\t-i <input_directory>.  Subdirectories are allowed.\n"
    printf "\t-o <output_directory>.  Any existing files will be removed.\n"
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

convert_month() {
    case "$1" in
        "01")
            printf "January"
            ;;
        "02")
            printf "February"
            ;;
        "03")
            printf "March"
            ;;
        "04")
            printf "April"
            ;;
        "05")
            printf "May"
            ;;
        "06")
            printf "June"
            ;;
        "07")
            printf "July"
            ;;
        "08")
            printf "August"
            ;;
        "09")
            printf "September"
            ;;
        "10")
            printf "October"
            ;;
        "11")
            printf "November"
            ;;
        "12")
            printf "December"
            ;;
        *)
            printf ""
            ;;
    esac
}

print_error() {
    red='\033[0;31m'
    reset='\033[0m' # No Color
    printf "${red}Error.${reset}  $1\n"
}

parse_args "$@"
validate_args

printf "Starting with input[%s] output[%s]\n" "$input_dir" "$output_dir"

# Trim '/' char if it exists.
output_dir=${output_dir%/}

# Clean the output directory.
rm -rf "${output_dir}"/*

# Find all the jpeg and png files recursively.
input_photos=$(find "$input_dir" -type f \( -iname "*.jpg" -o -iname "*.mp4" -o -iname "*.png" -o -iname "*.jpeg" \))
if [ "$?" -ne "0" ]; then
    printf "Error.  Unable to find photos\n"
    exit 0
fi

# Split the input into an array.
# Save old IFS
IFS_OLD=$IFS
IFS=$'\n'
input_array=($input_photos)

for photo in "${input_array[@]}"; do
    result="Processing"

    # Get photo name withouth the path.
    photo_name=$(basename "$photo")

    result="$result[$photo]"

    # Get the path without the photo name.
    photo_path=$(dirname $photo)

    # Get the file extension
    extension="${photo##*.}"

    # Get the creation date from the file.
    if [ "$extension" = "mp4" ] || [ "$extension" = "MP4" ]; then 
        datetime=$(exiftool -CreateDate "$photo")
    else
        datetime=$(exiftool -DateTimeOriginal "$photo")
    fi

    if [ "$?" -ne "0" ]; then
        printf "%s\n" "$result"
        print_error "Unable to get DateTimeOriginal with exiftool"
        continue
    fi

    # Example input from exiftool:
    # "Date/Time Original              : 2021:05:06 17:32:59"
    # Search for year:month.
    year_month=$(echo "$datetime" | grep -o -E "[0-9][0-9][0-9][0-9]:[0-9][0-9]")
    if [ "$?" -ne "0" ]; then
        printf "%s\n" "$result"
        print_error "Unable to parse year:month"
        continue
    fi

    year=$(echo "$year_month" | grep -o -E "[0-9][0-9][0-9][0-9]")
    month=$(echo "$year_month" | grep -o -E ":[0-9][0-9]")

    # Drop the ':' from the month.
    month="${month:1}"

    month=$(convert_month "$month")
    if [ -z "$month" ]; then
        printf "%s\n" "$result"
        print_error "Invalid month."
        continue
    fi

    result="$result Year[$year] Month[$month]"

    mkdir -p "./$output_dir/$year/$month"
    cp "$photo" "./$output_dir/$year/$month/$photo_name"
    printf "%s\n" "$result"
done

exit 0

