# Local development on Linux

Runs the chart on a local [kind](https://kind.sigs.k8s.io/) cluster, installed with Terraform.

Install Docker Engine, kubectl and terraform, then **kind v0.33+** (`cloud-provider-kind` requires
the `ServiceCIDR` API, Kubernetes 1.34+):

    curl -sSL -o /tmp/kind https://github.com/kubernetes-sigs/kind/releases/download/v0.33.0/kind-linux-amd64
    sudo install -m 0755 /tmp/kind /usr/local/bin/kind
    kind create cluster --name kind

Deploy (this also starts the `cloud-provider-kind` ingress controller container if needed):

    ./scripts/deploy-kind.sh
    ./scripts/curl-api.sh [path]

`deploy-kind.sh` builds the images, loads them into kind, applies Terraform, restarts both
deployments and waits for the ingress address.

To run the controller yourself:

    docker run -d --name cloud-provider-kind --rm \
      --network host \
      -v /var/run/docker.sock:/var/run/docker.sock \
      registry.k8s.io/cloud-provider-kind/cloud-controller-manager:v0.12.0

Without the ingress controller, use a port-forward instead:

    kubectl port-forward deployment/mono-api 3000:3000
    curl localhost:3000/api/users
