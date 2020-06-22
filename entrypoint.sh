#!/bin/sh -l

_jq() {
    echo ${1} | jq -r '.[] ${2}'
}

mbed_opts=$1
jobs=$2

echo "mbed_opts: '${mbed_opts}'"
echo "jobs: '${jobs}'"

# mbed_url=$(echo ${mbed_opts} | jq -r '.url')
# mbed_branch=$(echo ${mbed_opts} | jq -r '.branch')
# mbed_dir=${GITHUB_WORKSPACE}/tmp/mbed-os
# echo "cloning mbed from repo: '${mbed_url}' into '${mbed_dir}'"
# mkdir -p ${mbed_dir}
# git clone ${mbed_url} ${mbed_dir}
# cd ${mbed_dir}
# echo "checking out branch: ${mbed_branch}"
# git checkout ${mbed_branch}
# pip3 install -r requirements.txt
# cd ${GITHUB_WORKSPACE}

jobs_out="["

job_count=0
for row in $(echo ${jobs} | jq -r '.[] | @base64'); do

    echo ${row}

    name=$(echo ${row} | base64 --decode | jq -r '.name')
    loc=$(echo ${row} | base64 --decode | jq -r '.loc')
    cmd=$(echo ${row} | base64 --decode | jq -r '.cmd')

    [ "$name" = "null" ] && (name="mbed-compile-job" && echo "No name for job [${job_count}] defaulting to '${name}'")
    [ "$loc" = "null" ] && (loc="${name}_${job_count}" && echo "No location for '${name}' defaulting to '${loc}'")

    echo "name: '${name}'"
    echo "location for job: '${loc}'"
    echo "cmd: '${cmd}'"

    # job_loc=${GITHUB_WORKSPACE}/${loc}
    # rm -rf ${job_loc}
    # mkdir -p ${job_loc}

    # cd ${job_loc}
    
    # echo "making symbolic link from '${mbed_dir}' to '${job_loc}'"
    # ln -s ${mbed_dir}

    # mbed config root .
    # ls
    # ls mbed-os

    # mbed ${cmd} # || true # could use this to skip errors on build and continue to build other jobs

    cd ${GITHUB_WORKSPACE}

    # jobs_out+='{"name": ${name}, "loc": "${job_loc}", "cmd": "${cmd}"}, '
    ((job_count++))

done

# touch ./test-output.txt
# echo "this is a test file representing the output" >> ./test-output.txt
# echo "::set-output name=jobs::{\"name\": \"test\", \"output\": \"./test-output.txt\"}"

# jobs_out+='incomplete]'

jobs_out="test string for jobs_out"

echo "::set-output name=jobs::${jobs_out}"