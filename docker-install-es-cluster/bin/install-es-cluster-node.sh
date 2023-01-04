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
DEPLOYED_AS_CLUSTER="true"
SET_CONTAINER_MAX_LOCKED_MEMORY_UNLIMITED="true"


#=================================================================================
# customized config 
#=================================================================================
app_name="elasticsearch"
image_name="elasticsearch"
image_version="6.8.23"

es_java_opts="-Xms1g -Xmx1g"
es_cluster_name="es-cluster-kyps"
es_config_network_host="0.0.0.0"
es_config_discovery_zen_ping_unicast_hosts="['10.1.76.2', '10.1.76.3', '10.1.76.4']"
es_config_discovery_zen_minimum_master_nodes=1


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

  container_local_es_certs_dir="${container_local_conf_dir}/certs"
  container_es_main_config_file="${container_local_conf_dir}/elasticsearch.yml"
  es_certs_tar_gz_filepath="$(get_install_files_dir)/certs.tar.gz"
}


#=================================================================================
# docker deployment configs
#=================================================================================
setup_docker_deployment_configs() {
  container_environment_config=(
    "TZ=Asia/Shanghai",
    "node.name=${cluster_node_id}",
    "cluster.name=${es_cluster_name}",
    "bootstrap.memory_lock=true",
    "ES_JAVA_OPTS=${es_java_opts}",
  )
  
  container_volume_mappings=(
    "${container_es_main_config_file}:/usr/share/elasticsearch/config/elasticsearch.yml",
    "${container_local_data_dir}:/usr/share/elasticsearch/data",
    "${container_local_es_certs_dir}:/usr/share/elasticsearch/config/certs",
    "/etc/localtime:/etc/localtime",
  )
  
  # if run elasticsearch in simple-cluster mode (one node in a worker), no need to set port mappings, directly use host network
  container_port_mappings=(
    # "9200:9200"
  )
  
  container_sysctls_config=(
    # "sysctl_config_key1=sysctl_config_value1",
    # "sysctl_config_key2=sysctl_config_value2",
  )
  
  container_command_config=""
}


#=================================================================================
# customized operation functions
#=================================================================================
setup_sysctl_configs() {
  cat <<EOF > "/etc/sysctl.d/${app_name}.conf"
vm.max_map_count=262144
EOF

  sysctl -p
  sysctl -w vm.max_map_count=262144 > /dev/null
}

generate_container_es_main_config() {
  mkdir -p $container_local_conf_dir
  
  cat <<EOF > ${container_es_main_config_file}
network.host: ${es_config_network_host}
discovery.zen.ping.unicast.hosts: ${es_config_discovery_zen_ping_unicast_hosts}
discovery.zen.minimum_master_nodes: ${es_config_discovery_zen_minimum_master_nodes}
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.keystore.path: certs/elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: certs/elastic-certificates.p12
EOF
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
  
  generate_container_es_main_config
  
  mkdir -p $container_local_data_dir
  chown -R 1000:1000 $container_local_conf_dir
  chown -R 1000:1000 $container_local_data_dir
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
