#!/bin/sh

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

. "$script_dir"/common.sh

print_help() {
    printf "This script uses exiftool to determine a photos extension.\n"
    printf "If the output is incorrect, it fixes the extension.  Files\n"
    printf "are modifed in place.  Some of the photos from Google Takeout\n"
    printf "were jpg extensions, but were actually encoded as png.\n"
    printf "One input is required.\n"
    printf "\t-i <input_directory>.  Searches are recursive.\n"
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

validate_args() {
    if [ -z "$input_dir" ]; then
        printf "Error.  Provide an input directory.\n"
        exit 1
    fi
}


parse_args "$@"
validate_args

printf "Starting with input[%s]\n" "$input_dir"

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
    # Get the path without the photo name.
    photo_path=$(dirname $photo)

    # Get photo name withouth the path.
    photo_name=$(basename "$photo")

    # Get the first two byes of the file name.
    pre="${photo_name:0:2}"

    if [ "$pre" == "._" ]; then
        # Ignore the macos meta file.
        continue
    fi

    result="Processing[$photo]"

    # Get the file extension from the file name.
    extension=$(get_file_extension "$photo")

    # Get the file type from exiftool.
    exif_type=$(exiftool -FileType "$photo")
    if [ "$?" -ne "0" ]; then
        print_error "Unable to get file type with exiftool."
        continue
    fi

    # Example input from exiftool:
    # "File Type                       : JPEG"
    # Search for year:month.
    exif_type=$(echo "$exif_type" | grep -o -E ": .*")
    if [ "$?" -ne "0" ]; then
        printf "%s\n" "$result"
        print_error "Unable to parse file type."
        continue
    fi
    
    # Remove leading ": "
    exif_type=${exif_type:2}

    # Convert to lowercase.
    exif_type=$(to_lowercase "$exif_type")
    #file_is_jpg=$(is_jpg "$exif_type")

    # Verify this is a filetype that should be handled.
    if [[ "$exif_type" != "png" && "$exif_type" != "jpg" && "$exif_type" != "jpeg" && "$exif_type" != "mp4" ]]; then
        printf "$result Cannot handle %s [skipping]\n" "$exif_type"
        continue
    fi

    if [[ "$exif_type" == "jpg" || "$exif_type" == "jpeg" ]]; then
        if [[ "$extension" == "jpg" || "$jpeg" == "jpeg" ]]; then
            # Both are jpg or jpeg.  Do nothing.
            printf "$result jpeg == jpg [ok]\n"
            continue
        fi
    fi
    
    # Get the photo name without the extension.
    photo_name=$(echo "$photo_name" | sed "s/\.$extension//")

    if [ "$exif_type" != "$extension" ]; then
        # Change the file extension.
        photo_corrected="$photo_path/$photo_name.$exif_type"
        yellow_text=$(print_yellow "Renamed")
        result="$result $yellow_text [$photo_corrected]"

        res=$(mv "$photo" "$photo_corrected")
        if [ "$?" == "0" ]; then
            result="$result [ok]"
            printf "$result\n"
            continue
        fi

        # mv reported an error.
        printf "%s " "$result"
        print_error "mv unsuccessful"
        continue
    fi

    # Do nothing.
    printf "$result [ok]\n"
    continue
done

exit 0

