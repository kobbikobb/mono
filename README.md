# mono

## Prerequisites

You need Docker, kind, kubectl, terraform and cloud-provider-kind, plus a kind cluster:

    kind create cluster

### macOS

    brew install colima docker kind kubectl terraform cloud-provider-kind
    colima start

### Linux

Install Docker Engine and make sure your user can run `docker`. Then install kubectl and terraform from your package manager or their official install pages, and the two kind tools with Go:

    go install sigs.k8s.io/kind@latest
    go install sigs.k8s.io/cloud-provider-kind@latest

`cloud-provider-kind` runs under `sudo`, so it must be on root's path too:

    sudo install "$(go env GOPATH)/bin/cloud-provider-kind" /usr/local/bin/

## Deploy locally

    ./scripts/deploy-local.sh
    ./scripts/curl-api.sh [path]

## cluster

kind create cluster
kubectl config use-context kind-kind
kubectl config get-contexts

kind load docker-image users-api:dev

terraform plan / apply

### Ingress
brew install cloud-provider-kind

#### Run an ingress controller
sudo "$(command -v cloud-provider-kind)"

### Without ingress
kubectl port-forward deployment/api 3000:3000
