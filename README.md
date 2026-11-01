# mono

## cluster

kind create cluster
kubectl config use-context kind-kind
kubectl config get-contexts

kind load docker-image users-api:dev

terraform plan / apply

kubectl port-forward deployment/api 3000:3000

### Ingress
brew install cloud-provider-kind

#### Run an ingress controller
sudo "$(command -v cloud-provider-kind)"
