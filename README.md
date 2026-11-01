# mono

This repo demonstrates how to build and publish the artifacts of a small monorepo
(a Fastify API and a React web app) so others can run it on Kubernetes and OpenShift:

- **Container images** are built from `api/` and `web/` and published to ghcr.io by CI.
  They run as a non-root user with no fixed UID, as OpenShift requires.
- **A Helm chart** (`charts/mono`) deploys both. Its Ingress becomes a Route on OpenShift.
- **Terraform** (`terraform/`) installs the chart the way a customer would.
- **CI** tests everything end to end with Playwright, on Docker Compose and on kind
  under restricted pod security.

To try it on OpenShift, see [OPENSHIFT.md](OPENSHIFT.md). The rest of this file covers running it
locally on [kind](https://kind.sigs.k8s.io/) with Terraform and `cloud-provider-kind`.

Requires Docker, kubectl, terraform, and **kind v0.33+**. Its default node image
is Kubernetes 1.37; `cloud-provider-kind` needs the `ServiceCIDR` API, which only
exists in Kubernetes 1.34 and newer. Older kind releases will fail with
`failed to get service CIDRs`.

## macOS

    brew install colima docker kind kubectl terraform cloud-provider-kind
    colima start
    kind create cluster --name kind

Start the ingress controller in its own terminal:

    sudo cloud-provider-kind

With colima, `sudo` drops `DOCKER_HOST`, so pass the socket explicitly:

    sudo -E DOCKER_HOST="unix://$HOME/.colima/default/docker.sock" cloud-provider-kind

## Linux

Install Docker Engine, kubectl and terraform, then kind:

    curl -sSL -o /tmp/kind https://github.com/kubernetes-sigs/kind/releases/download/v0.33.0/kind-linux-amd64
    sudo install -m 0755 /tmp/kind /usr/local/bin/kind
    kind create cluster --name kind

Run the ingress controller as a container (no `sudo`):

    docker run -d --name cloud-provider-kind --rm \
      --network host \
      -v /var/run/docker.sock:/var/run/docker.sock \
      registry.k8s.io/cloud-provider-kind/cloud-controller-manager:v0.12.0

## Deploy

    ./scripts/deploy-kind.sh
    ./scripts/curl-api.sh [path]

`deploy-kind.sh` builds the images, loads them into kind, applies Terraform,
restarts both deployments and waits for the ingress address. On Linux it also starts the
controller container if needed.

## Docker Compose

Runs the api and web containers; web is at http://localhost:8080.

    ./scripts/deploy-docker.sh

## Without ingress

    kubectl port-forward deployment/mono-api 3000:3000
    curl localhost:3000/api/users
