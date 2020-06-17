#!/bin/sh -l

_jq() {
    echo ${1} | jq -r '.[] ${2}'
}

mbed_opts='$1'
jobs=$2

echo "mbed: ${mbed_opts}"
echo "jobs: ${jobs}"

# echo "${jobs}" | jq -r '.[]'

mbed_url=$(echo ${mbed_opts} | jq -r '.url')
mbed_branch=$(echo ${mbed_opts} | jq -r '.branch')
mbed_dir="tmp/mbed-os"
echo "cloning mbed from repo: '${mbed_url}' into '${mbed_dir}'"
mkdir -p ${mbed_dir}
git clone ${mbed_url} ${mbed_dir}
cd ${mbed_dir}
echo "checking out branch: ${mbed_branch}"
git checkout ${mbed_branch}
pip3 install -r requirements.txt
cd ${GITHUB_WORKSPACE}

for row in $(echo "${jobs}" | jq -r '.[] | @base64'); do

    name=$(_jq ${row} '.name')
    loc=$(_jq ${row} '.loc')
    cmd=$(_jq ${row} '.cmd')

    echo "name: ${name}"
    echo "location for job: ${loc}"
    echo "cmd: ${cmd}"

    rm -rf ${loc}
    mkdir -p ${loc}
    ln -s ${mbed_dir} "${loc}/mbed-os"
    cd ${loc}

    ${cmd}

done

touch ./test-output.txt
echo "this is a test file representing the output" >> ./test-output.txt
echo "::set-output name=jobs::{\"name\": \"test\", \"output\": \"./test-output.txt\"}"