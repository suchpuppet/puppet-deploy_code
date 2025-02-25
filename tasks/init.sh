#!/bin/bash

# Puppet Task Name: deploy_code
#
# This is where you put the shell code for your task.
#
# You can write Puppet tasks in any language you want and it's easy to
# adapt an existing Python, PowerShell, Ruby, etc. script. Learn more at:
# https://puppet.com/docs/bolt/0.x/writing_tasks.html
#
# Puppet tasks make it easy for you to enable others to use your script. Tasks
# describe what it does, explains parameters and which are required or optional,
# as well as validates parameter type. For examples, if parameter "instances"
# must be an integer and the optional "datacenter" parameter must be one of
# portland, sydney, belfast or singapore then the .json file
# would include:
#   "parameters": {
#     "instances": {
#       "description": "Number of instances to create",
#       "type": "Integer"
#     },
#     "datacenter": {
#       "description": "Datacenter where instances will be created",
#       "type": "Enum[portland, sydney, belfast, singapore]"
#     }
#   }
# Learn more at: https://puppet.com/docs/bolt/0.x/writing_tasks.html#ariaid-title11
#

if [[ -z $PT_environment ]]; then
  query_params="?environment=${PT_environment}"
else
  query_params=''
fi

if [[ -z $PT_ssl_dir ]]; then
  SSL_DIR=$(puppet config print --section main ssldir)
else
    SSL_DIR=$PT_ssl_dir
fi

echo "Deploying code to ${PT_environment} environment"
$PT_r10k_path deploy environment -pv

if [[ $? -eq 0 ]]; then
  echo "Deployed code to ${PT_environment} environment"
else
  echo "Could not deploy code to ${PT_environment} environment"
  exit 1
fi

PUPPETSERVER=$(puppet config print --section main server)

if [[ $PT_expire_cache ]]; then
  echo "Flushing ${PT_environment} environment cache"
  curl -f --cert $(puppet config print --section main hostcert) --key $(puppet config print --section main hostprivkey)  --cacert "${SSL_DIR}/certs/ca.pem" -X DELETE https://${PUPPETSERVER}:8140/puppet-admin-api/v1/environment-cache${query_params}

  if [[ $? -eq 0 ]]; then
    echo "Flushed ${PT_environment} environment cache"
  else
    echo "Failed to flush ${PT_environment} environment cache"
    exit 1
  fi
fi
