#!/bin/sh

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

. "$script_dir"/common.sh

print_help() {
    printf "TODO\n"
    printf "One input is required.\n"
    printf "\t-i <input_directory>.  Parent of \"Google Photos\".\n"
}

input_dir=""
output_dir=""

photo_metadata_known_keys=(
    "title"
    "description"
    "imageViews"
    "creationTime"
    "photoTakenTime"
    "geoData"
    "googlePhotosOrigin"
    "url"
    "geoDataExif"
    "appSource"
    "sharedAlbumComments"
    "trashed"
    "favorited"
)

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

# This function parses the meta json for the top level keys.
# It then compares that array of keys to an array of known
# keys.  If a key is discovered that is not on th known key
# list then an error is reported.  The key in question needs
# to be investigated to determine if to has useful metadata
# or not.  The schema google uses to generate the metadata is
# unknown so the keys must be discovered, unfortunately.
check_metadata_keys() {
    meta_filename="$1"

    # Get the top level keys for the metadata json file.
    photo_meta_keys=$(cat "$meta_filename" | jq 'keys[]')

    # Convert to an array of keys.
    IFS_OLD=$IFS
    IFS=$'\n'
    key_array=($photo_meta_keys)

    # For each key in the photo metadata json.
    for key in "${key_array[@]}"; do
        # Remove double quotes.
        key=$(echo "${key//\"}")

        # Check if this key is known already.
        # For each key in the known key list.
        found="0"
        for known_key in "${photo_metadata_known_keys[@]}"; do
            #printf "Against[%s]\n" "$known_key"
            if [ "$key" == "$known_key" ]; then
                found=""
            fi
        done

        # Alert the user that a new key was discovered.
        # The photo_meta_known_keys array will need to be updated.
        if [ "$found" == "0" ]; then
            printf "\t"
            print_error "Unknown metadata key[$key] file[$meta_filename]"
        fi
    done
} 

parse_args "$@"
validate_args

printf "Starting with directory[%s]\n" "$input_dir"

# Find all the directories.
photo_dirs=$(find "$input_dir"/Google\ Photos -type d -maxdepth 1 -mindepth 1)
if [ "$?" -ne "0" ]; then
    print_error "Unable to find \"Google Photos\" in $input_dir\n"
    exit 0
fi

# Split the input into an array.
# Save old IFS
IFS_OLD=$IFS
IFS=$'\n'
photo_array=($photo_dirs)

image_extensions="(jpg|JPG|jpeg|JPEG|png|PNG|mp4|MP4)"

album_count=0
for photo_dir in "${photo_array[@]}"; do
    #printf "Directory[$photo_dir]\n"

    # Try to get the album title from metadata.json
    album_count=$((album_count + 1))
    album_title=""
    if [ -f "$photo_dir/metadata.json" ]; then
        album_title=$(cat "$photo_dir/metadata.json" | yq -e '.title' 2>/dev/null)

        if [ "$?" -ne "0" ]; then
            # No album title in the json.
            album_title=""
        fi
    fi

    printf "Directory[%s] AlbumTitle[%s]\n" "$photo_dir" "$album_title"

    # Find all meta files in the album dir.
    photo_meta_files=$(find "$photo_dir" -type f \( -iname "*.jpg.*.json" -o -iname "*.mp4.*.json" -o -iname "*.png.*.json" -o -iname "*.jpeg.*.json" \))
    IFS_OLD=$IFS
    IFS=$'\n'
    meta_array=($photo_meta_files)

    # For each meatdata file in the dir.
    for photo_meta_file in "${meta_array[@]}"; do
        result="Meta[$photo_meta_file]"
        # printf "\t%s\n" "$photo_meta_file"
        # Check for the json tags and report unknowns.
        check_metadata_keys "$photo_meta_file"

        # Get the matching png/jpg/mp3 image.
        # Remove everything after the first '.' estension.
        photo_basename=$(echo "$photo_meta_file" | sed -E "s/"\.$image_extensions\..*\.json"//")
        if [ "$?" -ne 0 ]; then
            printf "%s " "$result"
            print_error "Cannot get basename."
            continue
        fi

          # Get the path without the file name.
          path=$(dirname "$photo_meta_file")

      # Added trailing '/' if needed to the path.
      last_char="${path#"${path%?}"}"
      if [ "$last_char" != "/" ]; then
          path="$path/"
      fi

      # Remove the path from the basename.  Use '|' delimiter.
      # Example: "path/to/photo/mountanins"
      # becomes "mountains"
      photo_basename=$(echo "$photo_basename" | sed -E "s|$path||")

      # Find a matching photo
      photo=$(find "$path" -type f \( -iname "$photo_basename.jpg" -o -iname "$photo_basename.mp4" -o -iname "$photo_basename.png" -o -iname "$photo_basename.jpeg" \))
      if [ "$?" -ne "0" ]; then
          printf "\t%s" "$result"
          print_error " Find error."
          continue
      fi

      if [ "$photo" == "" ]; then
          # Failed to find a photo to match the json.
          printf "\t%s" "$result"
          print_error " Unmatched json meta file."
          continue
      fi

      Parase meta from the file then encode in the photo.
      result="$result Paired[$photo]"
      printf "\t%s\n" "$result"
  done
done

printf "AlbumCount[%d]\n" "$album_count"
exit 0

