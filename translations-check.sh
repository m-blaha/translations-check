#!/bin/bash

# Function to print usage information
print_usage() {
    echo "Usage: $(basename "$0") [options] pot-file distgit-po-dir output-dir"
    echo "Options:"
    echo "  -h, --help     Display this help message"
    echo "  --langs        Languages to check (comma-separated, default ko,ja,zh_CN,fr)"
}

# Default value for languages
default_languages=("ko" "ja" "zh_CN" "fr")
languages=("${default_languages[@]}")

# Parse long options using getopt
options=$(getopt -o h --long help,languages: -n "$(basename "$0")" -- "$@")
if [ $? -ne 0 ]; then
    print_usage
    exit 1
fi
eval set -- "$options"

# Process options and arguments
while true; do
    case "$1" in
        -h | --help)
            print_usage
            exit 0
            ;;
        --langs)
            IFS=',' read -ra languages <<< "$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Error: Invalid option"
            print_usage
            exit 1
            ;;
    esac
done

# Check for positional arguments
if [[ $# -lt 3 ]]; then
    echo "Error: pot-file, distgit-po-dir, and output-dir are required."
    print_usage
    exit 1
fi
potfile="$1"
distgitpodir="$2"
outdir="$3"

# prepare clean output directory
rm -rf "${outdir}"
mkdir "${outdir}"

statsfile=$(realpath "${outdir}/stats.txt")

for lang in "${languages[@]}"; do
    echo "Processing language: $lang"
    langfile_in=$(realpath "${distgitpodir}/${lang}.po")
    langfile_out=$(realpath "${outdir}/${lang}.po")
    echo "${lang}" >> "${statsfile}"
    # copy also pot file to the output dir
    cp "$potfile" "$outdir"
    # merge current distgit po with the latest upstream pot file
    msgmerge --no-fuzzy-matching "$langfile_in" "$potfile" > "$langfile_out"
    # generate statistics for the lang
    msgfmt --statistics "$langfile_out" &>> "$statsfile"
done

