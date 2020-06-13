#!/bin/sh -l

echo "mbed-os-url: $1"
echo "jobs: $2"

for row in $(echo "${jobs}" | jq -r '.[] | @base64'); do
    _jq() {
     echo ${row} | base64 --decode | jq -r ${1}
    }

   echo $(_jq '.name')
done