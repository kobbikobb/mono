# mono

A small Fastify API deployed to a local [kind](https://kind.sigs.k8s.io/) cluster
with Terraform, exposed through `cloud-provider-kind`.

## Prerequisites

- Docker
- kind v0.33 or newer (creates Kubernetes 1.37 by default)
- kubectl
- terraform

`cloud-provider-kind` v0.12 uses the Kubernetes `ServiceCIDR` API, which is only
served by Kubernetes 1.34 and newer. Older kind releases default to older node
images and the ingress controller will fail with:

    failed to get service CIDRs: the server could not find the requested resource

Use a recent kind so the cluster is new enough.

### macOS

    brew install colima docker kind kubectl terraform
    brew install cloud-provider-kind
    colima start
    kind create cluster

### Linux

Install Docker Engine and make sure your user can run `docker`, then install
kubectl and terraform from your package manager or their official install pages.

Install kind (v0.33.0 here; check the releases page for the latest):

    curl -sSL -o /tmp/kind https://github.com/kubernetes-sigs/kind/releases/download/v0.33.0/kind-linux-amd64
    install -m 0755 /tmp/kind ~/.local/bin/kind

Create the cluster. No `--image` flag is needed; the default node image is
Kubernetes 1.37, which satisfies the `ServiceCIDR` requirement:

    kind create cluster --name kind

On Linux `cloud-provider-kind` does **not** need `sudo` when it runs as a
container and your user can access Docker. Run it like this instead (once, in
the background):

    docker run -d --name cloud-provider-kind --rm \
      --network host \
      -v /var/run/docker.sock:/var/run/docker.sock \
      registry.k8s.io/cloud-provider-kind/cloud-controller-manager:v0.12.0

If you prefer the host binary, put it somewhere `sudo` can find it:

    go install sigs.k8s.io/cloud-provider-kind@latest
    sudo install "$(go env GOPATH)/bin/cloud-provider-kind" /usr/local/bin/

## Deploy locally

    ./scripts/deploy-local.sh
    ./scripts/curl-api.sh [path]

`deploy-local.sh` builds the image, loads it into kind, applies Terraform,
restarts the deployment, and (on Linux) starts the `cloud-provider-kind`
container if it is not already running.

`curl-api.sh` reads the address that the ingress controller assigned to the
ingress and curls it. The default path is `/api/users`.

## Manual steps

    kind create cluster --name kind
    kubectl config use-context kind-kind

    docker build -t users-api:dev api
    kind load docker-image users-api:dev --name kind

    terraform -chdir=terraform init
    terraform -chdir=terraform apply

### Ingress controller

Start `cloud-provider-kind` before or after deploying; it watches for new
ingresses and routes them. On Linux use the container command from above. On
macOS run the binary in its own terminal:

    sudo "$(command -v cloud-provider-kind)"

### Without ingress

    kubectl port-forward deployment/api 3000:3000
    curl localhost:3000/api/users
