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
DEPLOYED_AS_CLUSTER="false"


#=================================================================================
# customized config 
#=================================================================================
app_name="redis"
image_name="redis"
image_version="7.0.5"
redis_port=16379
redis_password="redis123"
redis_opts="--requirepass ${redis_password}"


#=================================================================================
# os and software version requirements, commands requirements
#=================================================================================
required_commands="docker"
# required_min_os_version="centos_7.2, ubuntu_18.04"


#=================================================================================
# parse internal config
#=================================================================================
parse_internal_config() {
  container_name=$(get_docker_container_name $image_name $image_version)
  container_local_conf_dir="$(get_container_local_conf_dir)"
  container_local_data_dir="$(get_container_local_data_dir)"
}


#=================================================================================
# docker deployment configs
#=================================================================================
setup_docker_deployment_configs() {
  container_environment_config=(
    "TZ=Asia/Shanghai",
  )
  
  container_volume_mappings=(
    "${container_local_data_dir}:/data",
  )
  
  container_port_mappings=(
    "${redis_port}:6379",
  )
  
  container_sysctls_config=(
    "net.core.somaxconn=511",
  )
  
  container_command_config="redis-server ${redis_opts}"
}


#=================================================================================
# customized operation functions
#=================================================================================
setup_sysctl_configs() {
  cat <<EOF > "/etc/sysctl.d/${app_name}.conf"
vm.overcommit_memory=1
EOF

  sysctl -p
  sysctl -w vm.overcommit_memory=1 > /dev/null
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
  setup_docker_deployment_configs
  setup_sysctl_configs
  
  mkdir -p "${container_local_data_dir}"
}


#=================================================================================
# Step 2: do install app
#=================================================================================
step_2_do_install_app() {
  start_docker_container $app_name $image_name $image_version
}


#=================================================================================
# Step 3: post process after install
#=================================================================================
step_3_post_process_after_install() {
  generate_view_logs_shell_script $app_name $container_name
  println_script_total_time_desc_and_exit
}


#=================================================================================
# MAIN ENTRY POINT
#=================================================================================
if $(is_deployed_as_cluster); then
  [ $# -ne 1 ] && \
    println_one_line_usage "$(basename $0) <cluster_node_id>" && \
    exitscript
  cluster_node_id=$1
fi

step_1_prepare_before_install

step_2_do_install_app

step_3_post_process_after_install
