#!/bin/bash

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 input.txt output.txt"
  exit 1
fi

awk 'NR==1 { lon1=$1; lat1=$2; next }
{
    printf "%.4f %.4f %.4f %.4f\n", lon1, lat1, $1, $2;
    lon1=$1; lat1=$2
}' "$1" > "$2"

