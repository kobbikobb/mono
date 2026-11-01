# Local development on macOS

Runs the chart on a local [kind](https://kind.sigs.k8s.io/) cluster, installed with Terraform.

Needs **kind v0.33+**: `cloud-provider-kind` requires the `ServiceCIDR` API (Kubernetes 1.34+),
and older kind releases fail with `failed to get service CIDRs`.

    brew install colima docker kind kubectl terraform cloud-provider-kind
    colima start
    kind create cluster --name kind

Start the ingress controller in its own terminal. With colima, `sudo` drops `DOCKER_HOST`,
so pass the socket explicitly:

    sudo -E DOCKER_HOST="unix://$HOME/.colima/default/docker.sock" cloud-provider-kind

Deploy:

    ./scripts/deploy-kind.sh
    ./scripts/curl-api.sh [path]

`deploy-kind.sh` builds the images, loads them into kind, applies Terraform, restarts both
deployments and waits for the ingress address.

Without the ingress controller, use a port-forward instead:

    kubectl port-forward deployment/mono-api 3000:3000
    curl localhost:3000/api/users
