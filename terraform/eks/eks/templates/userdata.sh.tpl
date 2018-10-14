#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh \
  --apiserver-endpoint '${cluster_endpoint}' \
  --b64-cluster-ca '${cluster_auth_base64}' \
  --kubelet-extra-args '${kubelet_extra_args}' '${cluster_name}'
