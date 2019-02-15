#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh \
  --apiserver-endpoint '${cluster_endpoint}' \
  --b64-cluster-ca '${cluster_auth_base64}' \
  --kubelet-extra-args '--node-labels=node-role.kubernetes.io/${worker_group_name}=${worker_group_name}' \
  '${cluster_name}'
