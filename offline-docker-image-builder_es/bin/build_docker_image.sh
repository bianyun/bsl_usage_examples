#!/usr/bin/env bash

SCRIPT_PATH="${0}"
while [ -h "${SCRIPT_PATH}" ]; do
  LS=`ls -ld "${SCRIPT_PATH}"`
  LINK=`expr "${LS}" : '.*-> \(.*\)$'`
  if [ `expr "${LINK}" : '/.*'` > /dev/null ]; then
    SCRIPT_PATH="${LINK}"
  else
    SCRIPT_PATH="`dirname "${SCRIPT_PATH}"`/${LINK}"
  fi
done
cd `dirname "${SCRIPT_PATH}"` > /dev/null
SCRIPT_DIR=`pwd`



#=================================================================================
# SCRIPT LEVEL CONFIG
#=================================================================================
BSL_SCRIPT_LIB_VERSION="1.0"
BSL_SCRIPT_LIB_DIR="$(realpath ${SCRIPT_DIR}/../../bash_script_lib_v${BSL_SCRIPT_LIB_VERSION})"
source $BSL_SCRIPT_LIB_DIR/init_script || exit 1
DEBUG_ENABLED="false"


#=================================================================================
# customized config 
#=================================================================================
app_name="elasticsearch"
app_version="6.8.23"
image_file_classifier="customized"


#=================================================================================
# os and software version requirements, commands requirements
#=================================================================================
required_commands="docker"
required_min_os_version="centos_7.2, ubuntu_22.04"


#=================================================================================
# parse internal config
#=================================================================================
parse_internal_config() {
  image_name=$(convert_app_name_to_docker_image_name $app_name)
  image_version=$(convert_app_version_to_docker_image_version $app_version)
  output_image_tag=$(resolve_docker_image_tag $image_name $image_version)
}


#=================================================================================
# Step 1: prepare before install
#=================================================================================
step_1_prepare_before_install() {
  _do_init_script
  parse_internal_config
}


#=================================================================================
# Step 2: do install app
#=================================================================================
step_2_do_install_app() {
  build_docker_image $output_image_tag
  save_docker_image_to_tar_gz $output_image_tag $image_file_classifier
}


#=================================================================================
# Step 3: post process after install
#=================================================================================
step_3_post_process_after_install() {
  log_success "Docker image building process has all been done successfully. "
  println_script_total_time_desc_and_exit
}


#=================================================================================
# MAIN ENTRY POINT
#=================================================================================

step_1_prepare_before_install

step_2_do_install_app

step_3_post_process_after_install
