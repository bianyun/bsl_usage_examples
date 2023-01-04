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
app_name="docker-ce"
app_version="20.10.21"


#=================================================================================
# required minimum os version or commands need to be existing
#=================================================================================
required_commands="tar systemctl grep wc"
required_min_os_version="ubuntu_22.04"


#=================================================================================
# parse internal config
#=================================================================================
parse_internal_config() {
  app_desc="$(resolve_app_desc $app_name $app_version)"
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
  install_docker_ce $app_name $app_version
}


#=================================================================================
# Step 3: post process after install
#=================================================================================
step_3_post_process_after_install() {
  show_msg_app_install_finished success "$app_desc"
  println_script_total_time_desc_and_exit
}


#=================================================================================
# MAIN ENTRY POINT
#=================================================================================

step_1_prepare_before_install

step_2_do_install_app

step_3_post_process_after_install
