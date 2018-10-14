- install ssl helper:
  - `go get -u github.com/cloudflare/cfssl/cmd/...`
- follow [instructions to create TLS config](https://github.com/uswitch/kiam/blob/master/docs/TLS.md)
  ```
  kubectl create secret generic kiam-server-tls -n kube-system \
  --from-file=ssl/ca.pem \
  --from-file=ssl/server.pem \
  --from-file=ssl/server-key.pem
  ```
  ```
  kubectl create secret generic kiam-agent-tls -n kube-system \
  --from-file=ssl/ca.pem \
  --from-file=ssl/agent.pem \
  --from-file=ssl/agent-key.pem
  ```
- changes on kiam deploy examples:
  - config network interface in agent.yaml
  - configure node selector in server.yaml and agent.yaml
  - configure ssl-certs host path in server.yaml
- apply kiam k8s config
  - `kubectl apply -f server-rbac.yaml`
  - `kubectl apply -f server.yaml`
  - `kubectl apply -f agent.yaml`