# mono

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
