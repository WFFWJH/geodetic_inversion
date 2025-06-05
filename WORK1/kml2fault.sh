#!/bin/bash

awk 'NR==1 { lon1=$1; lat1=$2; next }
{
    print lon1, lat1, $1, $2;
    lon1=$1; lat1=$2
}' $1 > $2

