# mono

A small Fastify API deployed to a local [kind](https://kind.sigs.k8s.io/) cluster
with Terraform and exposed through `cloud-provider-kind`.

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

    ./scripts/deploy-local.sh
    ./scripts/curl-api.sh [path]

`deploy-local.sh` builds the image, loads it into kind, applies Terraform,
restarts the API and waits for the ingress address. On Linux it also starts the
controller container if needed.

## OpenShift (MicroShift)

Runs the same API on a local MicroShift cluster via
[MINC](https://github.com/minc-org/minc). Requires a rootful Docker daemon plus
`oc` and `minc` on `PATH`; no Red Hat pull secret is needed.

    ./scripts/deploy-openshift.sh

The script creates or reuses a `microshift` container, loads the image into its
CRI-O, applies `openshift/manifests.yaml`, and prints the Route, e.g.
`http://api-mono.apps.127.0.0.1.nip.io:9080/api/users`.

Stop it with `minc --provider docker delete`.

## Without ingress

    kubectl port-forward deployment/api 3000:3000
    curl localhost:3000/api/users
