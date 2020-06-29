# compile-mbed-projects
run any number of custom mbed jobs and use the results in additional actions

## inputs

### `jobs`

**required** serialized json array with an object for each job 
```[{"name": "", "loc": "", "config": {"base": "", "tgt": "", "tool": ""}, "user": {}}, ...]```
* `name`: *optional* a string used to identify the job, defaults to 'mbed-job'
* `loc`: *optional* a string to specify the location of the job within the docker container, defaults to '$name_#' where '#' is the serial build id
* `config`: **required**
  * `base`: **required** a string of options to supply to mbed
  * `tgt`: *optional* a target specifier that will be supplied as '-m $tgt'
  * `tgt`: *optional* a toolchain specifier that will be supplied as '-t $tool'
* `user`: *optional* a user-specified json object that will be copied to the output (useful to pass information required by subsequent actions)

### `mbed`

*optional* serialized json object with mbed git repo information ```{"url": "", "branch": ""}```
* `url`: *optional* the url of the git repo to use for mbed, defaults to 'https://github.com/ARMmbed/mbed-os'
* `branch`: *optional* the branch of the mbed repo from which to run the jobs, defaults to 'master'

## outputs

### `jobs`

a serialized json array of resulting information from each job 
```[{"name": "", "loc": {"id": "", "root": ""}, "config": {"base": "", "tgt": "", "tool": ""}, "user": {}}, ...]```
* `name`: the name that was used for the build (either user-specified or default)
* `loc`:
  * `id`: the id used for the build (useful to navigate mbed build directory structure)
  * `root`: the path to the mbed build relative to ```GITHUB_WORKSPACE```
* `config`: the config object that was used for the build
* `user`: the user's data that has been passed through

## Example usage

This example demonstrates how multiple jobs can be run and the output can be used in subsequent steps. 

First this action is used to compile static libraries for a variety of different targets. Next the user data passed along with each target is used to copy the resulting library to the proper destination

```
jobs:
  build:
    name: Generate Variants
    runs-on: ubuntu-latest
    steps:
      - name: check out code
        uses: actions/checkout@v2.3.1
        with:
          path: arduino-apollo3
          fetch-depth: 0

      - name: build variant libs
        id: buildvariants
        uses: oclyke-actions/compile-mbed-projects@v0.0.0
        with:
          jobs: |
            [
              {"name": "artemis-redboard-atp-lib", "config": {"base": "compile --library --source=mbed-os", "tgt": "SFE_ARTEMIS_ATP", "tool": "GCC_ARM"}, "user": {"variant": {"name": "ARTEMIS_ATP", "loc": "variants/SFE_ARTEMIS_ATP"}}},
              {"name": "artemis-dev-kit-lib", "config": {"base": "compile --library --source=mbed-os", "tgt": "SFE_ARTEMIS_DK", "tool": "GCC_ARM"}, "user": {"variant": {"name": "ARTEMIS_DEV_KIT", "loc": "variants/SFE_ARTEMIS_DK"}}},
              {"name": "artemis-redboard-nano-lib", "config": {"base": "compile --library --source=mbed-os", "tgt": "SFE_ARTEMIS_NANO", "tool": "GCC_ARM"}, "user": {"variant": {"name": "ARTEMIS_NANO", "loc": "variants/SFE_ARTEMIS_NANO"}}},
              {"name": "artemis-thing-plus-lib", "config": {"base": "compile --library --source=mbed-os", "tgt": "SFE_ARTEMIS_THING_PLUS", "tool": "GCC_ARM"}, "user": {"variant": {"name": "ARTEMIS_THING_PLUS", "loc": "variants/SFE_ARTEMIS_THING_PLUS"}}},
              {"name": "edge-lib", "config": {"base": "compile --library --source=mbed-os", "tgt": "SFE_EDGE", "tool": "GCC_ARM"}, "user": {"variant": {"name": "EDGE", "loc": "variants/SFE_EDGE"}}},
              {"name": "edge2-lib", "config": {"base": "compile --library --source=mbed-os", "tgt": "SFE_EDGE2", "tool": "GCC_ARM"}, "user": {"variant": {"name": "EDGE2", "loc": "variants/SFE_EDGE2"}}}
            ]
          mbed: |
            {"url": "https://github.com/sparkfun/mbed-os-ambiq-apollo3", "branch": "ambiq-apollo3-dev"}

      - name: copy libs to variants
        run: |
          cd arduino-apollo3

          jobs='${{ steps.buildvariants.outputs.jobs }}'
          job_count=0

          for row in $(echo ${jobs} | jq -r '.[] | @base64'); do
            name="$(echo ${row} | base64 --decode | jq -r '.name')"
            loc="$(echo ${row} | base64 --decode | jq -r '.loc')"
            config="$(echo ${row} | base64 --decode | jq -r '.config')"
            user="$(echo ${row} | base64 --decode | jq -r '.user')"

            tgt="$(echo ${config} | jq -r -c '.tgt')"
            tool="$(echo ${config} | jq -r -c '.tool')"
            build_root="$(echo ${loc} | jq -r -c '.root')"
            build_id="$(echo ${loc} | jq -r -c '.id')"
            variant_root="$(echo ${user} | jq -r '.variant.loc')"

            echo ""
            echo "${job_count}:"
            echo "'${name}'"

            # copy the mbed static library
            src="./../${build_root}/BUILD/libraries/${build_id}/${tgt}/${tool}/libmbed-os.a"
            dest="./${variant_root}/mbed/libmbed-os.a"
            echo "copying '${src}' to '${dest}'"
            mkdir -p $(dirname $dest)
            cp $src $dest
```