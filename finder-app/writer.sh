writefile="$1"
writestr="$2"

if ! [ $# -eq 2 ]
    then
        echo "Error: Missing required arguments. Expected 2 arguments, 2 were not given"
        echo "Usage: $0 <path_to_dir> <search_string>"
        exit 1
    fi

mkdir -p "$(dirname "$writefile")"
echo "$writestr" > "$writefile"

# if [ -w $writefile ]
#     then
#         echo "hello world"
#     # else
#     #     touch $writefile
#     #     echo "$writestr" > $writefile
#     fi