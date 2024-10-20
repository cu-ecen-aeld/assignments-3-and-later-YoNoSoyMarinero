#!/usr/bin/env bash


filesdir=$1
searchstr=$2

if [ -z "$filesdir" ] || [ -z "$searchstr" ]; then
	echo "Error: you need to pass two arguments filesdir and searchstr"
	exit 1
fi


if [ ! -d "$filesdir" ]; then
	echo "Error: that directory doesn't exist"
	exit 1
fi

matching_files=$(grep -l --exclude-dir=* "$searchstr" "$filesdir"/* | wc -l)
total_matching_lines=$(grep -o --exclude-dir=* "$searchstr" "$filesdir"/* | wc -l)

echo "The number of files are $matching_files and the number of matching lines are $total_matching_lines"

