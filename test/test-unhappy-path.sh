#!/bin/bash

DESCRIBE="Unhappy path"
  examples_failed=0
  root_dir=$(dirname $0)

GREEN='\033[0;32m'
RED='\033[0;31m'
NOCOLOR='\033[0m'

# Tests
IT="exits 1 with a helpful message if no CA keys are specified"
  output=$(${root_dir}/../extract-vars-store-from-manifests.sh \
    -cf ${root_dir}/fixture/source-cf-manifest.yml \
    -d ${root_dir}/fixture/source-diego-manifest.yml)
  exit_code=$?
  expected_output=""
  if [ "$exit_code" == "1" ]; then
    echo -e ${GREEN} PASS ${NOCOLOR} - ${IT}
  else
    examples_failed=1
    echo -e ${RED} FAIL ${NOCOLOR} - ${IT}
  fi

IT="has a helpful message if no CA keys are specified"
  if echo -e "${output}" | grep -q "Certificate Authority Key stub" ; then
    echo -e ${GREEN} PASS ${NOCOLOR} - ${IT}
  else
    examples_failed=1
    echo -e ${RED} FAIL ${NOCOLOR} - ${IT} - expected "${output}" to == "${expected_output}"
  fi

IT="exits 1 with a helpful message if no CF manifest is specified"
  output=$(${root_dir}/../extract-vars-store-from-manifests.sh \
    -d ${root_dir}/fixture/source-diego-manifest.yml)
  exit_code=$?
  expected_output=""
  if [ "$exit_code" == "1" ]; then
    echo -e ${GREEN} PASS ${NOCOLOR} - ${IT}
  else
    examples_failed=1
    echo -e ${RED} FAIL ${NOCOLOR} - ${IT}
  fi

IT="has a helpful message if no CF manifest is specified"
  if echo -e "${output}" | grep -q "CF manifest" ; then
    echo -e ${GREEN} PASS ${NOCOLOR} - ${IT}
  else
    examples_failed=1
    echo -e ${RED} FAIL ${NOCOLOR} - ${IT} - expected "${output}" to == "${expected_output}"
  fi

IT="exits 1 if no diego manifest is specified"
  output=$(${root_dir}/../extract-vars-store-from-manifests.sh \
    -cf ${root_dir}/fixture/source-cf-manifest.yml)
  exit_code=$?
  expected_output=""
  if [ "$exit_code" == "1" ]; then
    echo -e ${GREEN} PASS ${NOCOLOR} - ${IT}
  else
    examples_failed=1
    echo -e ${RED} FAIL ${NOCOLOR} - ${IT}
  fi

IT="has a helpful message if no Diego manifest is specified"
  if echo -e "${output}" | grep -q "Diego manifest" ; then
    echo -e ${GREEN} PASS ${NOCOLOR} - ${IT}
  else
    examples_failed=1
    echo -e ${RED} FAIL ${NOCOLOR} - ${IT} - expected "${output}" to == "${expected_output}"
  fi

IT="has a helpful message if any CA keys are missing"
  all_the_cas="diego_ca etcd_ca etcd_peer_ca uaa_ca consul_agent_ca loggregator_ca"
  for item in $all_the_cas
  do
    missing_one_ca_file=$(mktemp)
    grep -v $item ${root_dir}/fixture/ca-private-keys.yml > $missing_one_ca_file
    output=$(${root_dir}/../extract-vars-store-from-manifests.sh \
      -cf ${root_dir}/fixture/source-cf-manifest.yml \
      -d ${root_dir}/fixture/source-diego-manifest.yml \
      -ca ${missing_one_ca_file} 2> /dev/null)
    if echo -e "${output}" | grep -q -e "$item .* not found in"; then
      echo -e ${GREEN} PASS ${NOCOLOR} - ${IT} - ${item}
    else
      examples_failed=1
      echo -e ${RED} FAIL ${NOCOLOR} - ${IT} - ${item}
    fi
  done


function test_cf_networking_variable_extraction() {
  local required_property
  required_property="${1}"

  local error_message
  error_message="${2}"

  local missing_a_property
  missing_a_property=$(mktemp)
  grep -v $required_property ${root_dir}/fixture/source-diego-manifest.yml > $missing_a_property

  local exit_code
  local error_output
  error_output="$(${root_dir}/../extract-vars-store-from-manifests.sh \
    -cf ${root_dir}/fixture/source-cf-manifest.yml \
    -d  $missing_a_property \
    -ca ${root_dir}/fixture/ca-private-keys.yml \
    -N 2>&1 > /dev/null)"

  exit_code=$?

  IT="exits 1 if network-related properties are missing when -N is supplied"
    if [ "$exit_code" == "1" ]; then
      echo -e ${GREEN} PASS ${NOCOLOR} - ${IT} - $required_property
    else
      examples_failed=1
      echo -e ${RED} FAIL ${NOCOLOR} - ${IT} - $required_property
    fi
  IT="has a helpful message if network-related properties are missing when -N is supplied"
    if echo -e "${error_output}" | grep -q -e $error_message ; then
      echo -e ${GREEN} PASS ${NOCOLOR} - ${IT} - $required_property
    else
      examples_failed=1
      echo -e ${RED} FAIL ${NOCOLOR} - ${IT} - $required_property
    fi
}

test_cf_networking_variable_extraction "policy_server_ca_cert" "policy_server_internal.ca_cert"
test_cf_networking_variable_extraction "policy_server_cert" "policy_server_internal.server_cert"
test_cf_networking_variable_extraction "policy_server_key" "policy_server_internal.server_key"
test_cf_networking_variable_extraction "policy_server_uaa_client_secret" "policy_server.uaa_client_secret"

test_cf_networking_variable_extraction "silk_controller_ca_cert" "silk_controller.ca_cert"
test_cf_networking_variable_extraction "silk_controller_server_cert" "silk_controller.server_cert"
test_cf_networking_variable_extraction "silk_controller_server_key" "silk_controller.server_key"
test_cf_networking_variable_extraction "silk_daemon_ca_cert" "silk_daemon.ca_cert"
test_cf_networking_variable_extraction "silk_daemon_client_cert" "silk_daemon.client_cert"
test_cf_networking_variable_extraction "silk_daemon_client_key" "silk_daemon.client_key"

test_cf_networking_variable_extraction "vxlan_policy_agent_ca_cert" "vxlan_policy_agent.ca_cert"
test_cf_networking_variable_extraction "vxlan_policy_agent_client_cert" "vxlan_policy_agent.client_cert"
test_cf_networking_variable_extraction "vxlan_policy_agent_client_key" "vxlan_policy_agent.client_key"

function test_routing_deployment_variable_extraction() {
  local required_property
  required_property="${1}"

  local error_message
  error_message="${2}"

  local missing_a_property
  missing_a_property=$(mktemp)
  grep -v $required_property ${root_dir}/fixture/source-cf-manifest-with-routing.yml > $missing_a_property

  local exit_code
  local error_output
  error_output="$(${root_dir}/../extract-vars-store-from-manifests.sh \
    -cf $missing_a_property \
    -d  ${root_dir}/fixture/source-diego-manifest.yml \
    -ca ${root_dir}/fixture/ca-private-keys.yml \
    -r 2>&1 > /dev/null)"

  exit_code=$?
  IT="exits 1 if routing-related properties are missing when -r is supplied"
    if [ "$exit_code" == "1" ]; then
      echo -e ${GREEN} PASS ${NOCOLOR} - ${IT} - $required_property
    else
      examples_failed=1
      echo -e ${RED} FAIL ${NOCOLOR} - ${IT} - $required_property
    fi
  IT="has a helpful message if routing-related properties are missing when -r is supplied"
    if echo -e "${error_output}" | grep -q -e $error_message ; then
      echo -e ${GREEN} PASS ${NOCOLOR} - ${IT} - $required_property
    else
      examples_failed=1
      echo -e ${RED} FAIL ${NOCOLOR} - ${IT} - $required_property
    fi
}

test_routing_deployment_variable_extraction "uaa-emitter-secret" "uaa_clients_tcp_emitter_secret"
test_routing_deployment_variable_extraction "uaa-tcp-secret" "uaa_clients_tcp_router_secret"

CONTEXT="CF networking private keys"
  missing_a_private_key=$(mktemp)
  grep -v policy_server_ca_key < ${root_dir}/fixture/ca-private-keys.yml > ${missing_a_private_key}
  echo -e "${CONTEXT}:"
  error_output="$(${root_dir}/../extract-vars-store-from-manifests.sh \
    -cf ${root_dir}/fixture/source-cf-manifest.yml \
    -d  ${root_dir}/fixture/source-diego-manifest.yml \
    -ca ${missing_a_private_key} \
    -N 2>&1 > /dev/null)"

  exit_code=$?
  IT="should require private keys for cf networking CAs when -N is specified"
    if [ "$exit_code" == "1" ]; then
      echo -e ${GREEN} PASS ${NOCOLOR} - ${IT} - policy_server_ca_key
    else
      examples_failed=1
      echo -e ${RED} FAIL ${NOCOLOR} - ${IT} - policy_server_ca_key
    fi
  IT="should have a helpful message when private keys for cf networking CAs are missing"
    if echo -e "${error_output}" | grep -q -e "policy_server_ca.private_key" ; then
      echo -e ${GREEN} PASS ${NOCOLOR} - ${IT} - policy_server_ca_key
    else
      examples_failed=1
      echo -e ${RED} FAIL ${NOCOLOR} - ${IT} - policy_server_ca_key
    fi

function test_locket_variable_extraction() {
  local required_property
  required_property="${1}"

  local error_message
  error_message="${2}"

  local missing_a_property
  missing_a_property=$(mktemp)
  grep -v $required_property ${root_dir}/fixture/source-diego-manifest.yml > $missing_a_property

  local exit_code
  local error_output
  error_output="$(${root_dir}/../extract-vars-store-from-manifests.sh \
    -cf ${root_dir}/fixture/source-cf-manifest.yml \
    -d  $missing_a_property \
    -ca ${root_dir}/fixture/ca-private-keys.yml \
    -Q 2>&1 > /dev/null)"

  exit_code=$?

  IT="exits 1 if locket properties are missing when -Q is supplied"
    if [ "$exit_code" == "1" ]; then
      echo -e ${GREEN} PASS ${NOCOLOR} - ${IT} - $required_property
    else
      examples_failed=1
      echo -e ${RED} FAIL ${NOCOLOR} - ${IT} - $required_property
    fi
  IT="has a helpful message if locket properties are missing when -Q is supplied"
    if echo -e "${error_output}" | grep -q -e $error_message ; then
      echo -e ${GREEN} PASS ${NOCOLOR} - ${IT} - $required_property
    else
      examples_failed=1
      echo -e ${RED} FAIL ${NOCOLOR} - ${IT} - $required_property
    fi
}

test_locket_variable_extraction "locket-server-cert" "diego_locket_server.certificate"
test_locket_variable_extraction "locket-server-key" "diego_locket_server.private_key"
test_locket_variable_extraction "service-cf-internal-ca-cert" "diego_locket_server.ca"
test_locket_variable_extraction "diego-auctioneer-bbs-client-cert" "diego_locket_client.cert"
test_locket_variable_extraction "diego-auctioneer-bbs-client-key" "diego_locket_client.private_key"
test_locket_variable_extraction "locket-database-password" "locket_database_password"

# "test framework" exit code matching/reporting
if [[ "${examples_failed}" > 0 ]]; then
  echo -e ${DESCRIBE} ${RED} FAILED! ${NOCOLOR}
  exit 1
else
  echo -e ${DESCRIBE} ${GREEN} PASSED! ${NOCOLOR}
  exit 0
fi

