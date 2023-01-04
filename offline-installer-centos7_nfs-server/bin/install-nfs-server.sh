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
app_name="nfs-server"
app_version=""
systemd_service_name="nfs-server"
nfs_server_shared_dir="/data/nfs_server_shared_dir_fsir"
nfs_server_exports_config="${nfs_server_shared_dir} 10.1.76.0/24(rw,sync,no_root_squash,no_all_squash)"
nfs_server_exports_filepath="/etc/exports"


#=================================================================================
# required minimum os version or commands need to be existing
#=================================================================================
required_commands="yum rpm tar systemctl grep wc"
required_min_os_version="centos_7.2"


#=================================================================================
# parse internal config
#=================================================================================
parse_internal_config() {
  app_desc="$(resolve_app_desc $app_name $app_version)"
}


#=================================================================================
# customized operation functions
#=================================================================================
setup_nfs_server_export_config() {
  if [ ! -f $nfs_server_exports_filepath ] || \
        [ $(grep "${nfs_server_exports_config}" ${nfs_server_exports_filepath} |wc -l) -eq 0 ]; then
    mkdir -p $nfs_server_shared_dir
    echo "${nfs_server_exports_config}" >> $nfs_server_exports_filepath
    exec_command_quietly "systemctl restart $systemd_service_name"
  fi
}

install_nfs_server() {
  log_notice "Start to install ${app_desc}..."
  install_app_as_systemd_service $app_name $systemd_service_name $app_version
  setup_netconfig_file_if_needed
  setup_nfs_server_export_config
}


#=================================================================================
# Step 0: init script
#=================================================================================
_do_init_script


#=================================================================================
# Step 1: prepare before install
#=================================================================================
step_1_prepare_before_install() {
  parse_internal_config
}


#=================================================================================
# Step 2: do install app
#=================================================================================
step_2_do_install_app() {
  install_nfs_server
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
