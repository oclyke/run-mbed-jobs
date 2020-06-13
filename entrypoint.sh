#!/bin/sh -l

MBED=$1
JOBS=$2

echo "mbed: ${MBED}"
echo "jobs: ${JOBS}"

echo $JOBS | jq -c '.'

for row in $(echo "${jobs}" | jq -r '.[] | @base64'); do
    _jq() {
     echo ${row} | base64 --decode | jq -r ${1}
    }

   echo $(_jq '.name')
done

touch ./test-output.txt
echo "this is a test file representing the output" >> ./test-output.txt
echo "::set-output name=jobs::{\"name\": \"test\", \"output\": \"./test-output.txt\"}"