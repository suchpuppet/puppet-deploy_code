#!/bin/bash

# Puppet Task Name: deploy_code
set -e
export PATH="/opt/puppetlabs/puppet/bin:/opt/puppetlabs/bin:/opt/puppetlabs/bolt/bin:$PATH"

# Validate and set environment
if [[ -z "$PT_environment" ]]; then
  query_params="?environment=${PT_environment}"
else
  query_params=''
fi

# Set SSL Directory
SSL_DIR="${PT_ssl_dir:-$(puppet config print --section main ssldir)}"

# Deploy code using r10k
if $PT_r10k_path deploy environment -pv; then
  printf '{"status":"success", "message":"Deployed code to %s environment"}\n' "$PT_environment"
else
  printf '{"status":"error", "message":"Failed to deploy code to %s environment"}\n' "$PT_environment" >&2
  exit 1
fi

# Get Puppet Server
PUPPETSERVER=$(puppet config print --section main server)

# Flush environment cache if requested
if [[ "$PT_expire_cache" == "true" ]]; then
  curl -fsS --cert "$(puppet config print --section main hostcert)" \
             --key "$(puppet config print --section main hostprivkey)" \
             --cacert "${SSL_DIR}/certs/ca.pem" \
             -X DELETE "https://${PUPPETSERVER}:8140/puppet-admin-api/v1/environment-cache${query_params}" || {
    printf '{"status":"error", "message":"Failed to flush %s environment cache"}\n' "$PT_environment" >&2
    exit 1
  }
  printf '{"status":"success", "message":"Flushed %s environment cache"}\n' "$PT_environment"
fi
