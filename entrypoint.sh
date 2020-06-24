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

    echo ""
    echo "${job_count}:"

    name=$(echo ${row} | base64 --decode | jq -r -c '.name')
    loc=$(echo ${row} | base64 --decode | jq -r -c '.loc')
    config=$(echo ${row} | base64 --decode | jq -r -c '.config')
    user=$(echo ${row} | base64 --decode | jq -r -c '.user')

    tgt=$(echo ${config} | jq -r -c '.tgt')
    tool=$(echo ${config} | jq -r -c '.tool')
    base=$(echo ${config} | jq -r -c '.base')
    

    if [ "${name}" = "null" ]; then 
        name="mbed-compile-job"
        echo "\tNo name for job [${job_count}] defaulting to '${name}'"
    fi
    if [ "${loc}" = "null" ]; then
        loc="${name}_${job_count}" 
        echo "\tNo location for '${name}' defaulting to '${loc}'"
    fi

    loc="mbed-builds/${loc}"

    echo "\tname: '${name}'"
    echo "\tloc: '${loc}'"
    echo "\tconfig: '${config}'"
    echo "\t\ttgt: '$tgt'"
    echo "\t\ttool: '$tool'"
    echo "\t\textra: '$base'"
    echo "\tuser: '${user}'"

    loc=${GITHUB_WORKSPACE}/${loc}
    # rm -rf ${loc}
    # mkdir -p ${loc}

    # cd ${loc}
    
    # echo "making symbolic link from '${mbed_dir}' to '${loc}'"
    # ln -s ${mbed_dir}

    # mbed config root .
    # ls
    # ls mbed-os

    cmd="${base}"
    if [ ! -z "${tgt}" ]; then 
        echo "a target was provided"
        cmd="${cmd} -m ${tgt}"
    fi
    if [ ! -z "${tool}" ]; then 
        echo "a tool was provided"
        cmd="${cmd} -t ${tool}"
    fi

    # faking it for speed
    echo "mbed ${cmd}"
    lib_src="./${loc}/BUILD/libraries/libmbed-os/${tgt}/${tool}/libmbed-os.a"
    mkdir -p $(dirname $lib_src)
    touch $lib_src
    echo $(date) > $lib_src
    echo "this is stand-in text where the libmbed-os library should be" > $lib_src
    echo $(cat $lib_src)

    # mbed ${cmd} # || true # could use this to skip errors on build and continue to build other jobs

    cd ${GITHUB_WORKSPACE}

    # job_info=$(jq -n -r -c --arg job_name "$name" --arg job_loc "$loc" --arg job_cmd "$cmd" --arg job_args "$args" '{"name": $job_name, "loc": $job_loc, "cmd": $job_cmd, "args": $job_args}')
    job_info=$(jq -n -r -c "{\"name\": \"$name\", \"loc\": \"$loc\", \"config\": $config, \"user\": $user}")
    
    if [ "${job_count}" -ne "0" ]; then
        job_info=", ${job_info}"
    fi
    
    jobs_out="${jobs_out}${job_info}"
    
    job_count=$((job_count + 1))
done

jobs_out="${jobs_out}]"
echo "::set-output name=jobs::${jobs_out}"