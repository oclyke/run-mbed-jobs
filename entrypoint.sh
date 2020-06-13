#!/bin/sh -l

mbed=$1
jobs=$2

echo "mbed: ${mbed}"
echo "jobs: ${jobs}"

echo "${jobs}" | jq -r '.[] | @base64'

for row in $(echo "${jobs}" | jq -r '.[] | @base64'); do
    _jq() {
     echo ${row} | base64 --decode | jq -r ${1}
    }

   echo $(_jq '.name')
done

touch ./test-output.txt
echo "this is a test file representing the output" >> ./test-output.txt
echo "::set-output name=jobs::{\"name\": \"test\", \"output\": \"./test-output.txt\"}"