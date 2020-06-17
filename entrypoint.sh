#!/bin/sh -l

mbed=$1
jobs=$2

# echo "mbed: ${mbed}"
# echo "jobs: ${jobs}"

# echo "${jobs}" | jq -r '.[]'

mbed_dir="tmp/mbed-os"
mkdir -p ${mbed_dir}
git clone ${mbed} ${mbed_dir}

for row in $(echo "${jobs}" | jq -r '.[] | @base64'); do
    _jq() {
     echo ${row} | base64 --decode | jq -r ${1}
    }

    name=$(_jq '.name')
    loc=$(_jq '.loc')
    cmd=$(_jq '.cmd')

    echo "name: ${name}"
    echo "location for job: ${loc}"
    echo "cmd: ${cmd}"

    rm -rf loc
    mkdir -p loc
    ls loc

    ln -s ${mbed_dir} " ${loc}/mbed-os"

done

touch ./test-output.txt
echo "this is a test file representing the output" >> ./test-output.txt
echo "::set-output name=jobs::{\"name\": \"test\", \"output\": \"./test-output.txt\"}"