#!/bin/sh
filesdir="$1"
searchstr="$2"


# if [ $# -lt 2 ]
#     then
#         echo "Error: Missing required arguments. Expected 2 arguments, 2 were not given"
#         echo "Usage: $0 <path_to_dir> <search_string>"
#         exit 1
#     fi

if ! [ $# -eq 2 ]
    then
        echo "Error: Missing required arguments. Expected 2 arguments, 2 were not given"
        echo "Usage: $0 <path_to_dir> <search_string>"
        exit 1
    fi

if [ -d $filesdir ]
    then
        num_files=$(find "$filesdir" -type f | wc -l)
        num_matching_lns=$(grep -r "$searchstr" "$filesdir" | wc -l)
        echo "The number of files are $num_files and the number of matching lines are $num_matching_lns"
    else
        echo "Error: File $1 does not exist or is not a diretory"
        exit 1

    fi