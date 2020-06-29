#!/bin/sh -l

_jq() {
    echo ${1} | jq -r '.[] ${2}'
}

mbed_opts=$1
jobs=$2

echo "mbed_opts: '${mbed_opts}'"
echo "jobs: '${jobs}'"

mbed_url=$(echo ${mbed_opts} | jq -r '.url')
mbed_branch=$(echo ${mbed_opts} | jq -r '.branch')
if [ "${mbed_url}" = "null" ]; then 
    mbed_url="https://github.com/ARMmbed/mbed-os"
    echo "\tno mbed repo url specified - defaulting to '$mbed_url'"
fi
if [ "${mbed_branch}" = "null" ]; then 
    mbed_branch="master"
    echo "\tno branch specified - defaulting to '$mbed_branch'"
fi

mbed_dir=${GITHUB_WORKSPACE}/tmp/mbed-os
echo "cloning mbed from repo: '${mbed_url}' into '${mbed_dir}'"
mkdir -p ${mbed_dir}
git clone ${mbed_url} ${mbed_dir}
cd ${mbed_dir}
echo "checking out branch: ${mbed_branch}"
git checkout ${mbed_branch}
pip3 install -r requirements.txt
cd ${GITHUB_WORKSPACE}

jobs_out="["

job_count=0
for row in $(echo ${jobs} | jq -r '.[] | @base64'); do

    echo ""
    echo "${job_count}:"

    name=$(echo ${row} | base64 --decode | jq -r -c '.name')
    id=$(echo ${row} | base64 --decode | jq -r -c '.loc')
    config=$(echo ${row} | base64 --decode | jq -r -c '.config')
    user=$(echo ${row} | base64 --decode | jq -r -c '.user')

    tgt=$(echo ${config} | jq -r -c '.tgt')
    tool=$(echo ${config} | jq -r -c '.tool')
    base=$(echo ${config} | jq -r -c '.base')
    
    cmd="${base}"
    if [ "${name}" = "null" ]; then 
        name="mbed-job"
        echo "\tNo name for job [${job_count}] defaulting to '${name}'"
    fi
    if [ "${id}" = "null" ]; then
        id="${name}_${job_count}" 
        echo "\tNo location for '${name}' defaulting to '${id}'"
    fi
    if [ ! -z "${tgt}" ]; then 
        echo "a target was provided"
        cmd="${cmd} -m ${tgt}"
    fi
    if [ ! -z "${tool}" ]; then 
        echo "a tool was provided"
        cmd="${cmd} -t ${tool}"
    fi

    build_root="mbed-builds/${id}"
    rm -rf ${build_root}
    mkdir -p ${build_root}
    cd ${build_root}
    
    echo "linking '${mbed_dir}' to '${build_root}' symbolically"
    ln -s ${mbed_dir}
    mbed config root .
    mbed ${cmd} # || true # could use this to skip errors on build and continue to build other jobs

    cd ${GITHUB_WORKSPACE}
    loc=$(jq -n -r -c "{\"id\": \"$id\", \"root\": \"$build_root\"}")
    job_info=$(jq -n -r -c "{\"name\": \"$name\", \"loc\": $loc, \"config\": $config, \"user\": $user}")
    
    if [ "${job_count}" -ne "0" ]; then
        job_info=", ${job_info}"
    fi
    
    jobs_out="${jobs_out}${job_info}"
    
    job_count=$((job_count + 1))
done

jobs_out="${jobs_out}]"
echo "::set-output name=jobs::${jobs_out}"