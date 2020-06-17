#!/bin/sh -l

_jq() {
    echo "${1}" | base64 --decode | jq -r ${2}
}

mbed=$1
jobs=$2

# echo "mbed: ${mbed}"
# echo "jobs: ${jobs}"

# echo "${jobs}" | jq -r '.[]'

mbed_url=$(_jq ${mbed} '.url')
mbed_branch=$(_jq ${mbed} '.branch')
mbed_dir="tmp/mbed-os"
echo "cloning mbed from repo: ${mbed_url} into ${mbed_dir}"
mkdir -p ${mbed_dir}
git clone ${mbed_url} ${mbed_dir}
cd ${mbed_dir}
echo "checking out branch: ${mbed_branch}"
git checkout ${mbed_branch}
pip3 install -r requirements.txt
cd ${GITHUB_WORKSPACE}

for row in $(echo "${jobs}" | jq -r '.[] | @base64'); do
    _jq() {
        echo ${row} | base64 --decode | jq -r ${1}
    }

    name=$(_jq ${row} '.name')
    loc=$(_jq '.loc')
    cmd=$(_jq '.cmd')

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