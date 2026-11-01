# mono

A small monorepo with a Fastify API and a React web UI. The API is packaged as a
Helm chart and published to GitHub Container Registry, so the same chart runs on
Kubernetes (Ingress) or OpenShift (Route).

## Install

Kubernetes, behind an Ingress (an ingress controller must already exist):

    helm install mono oci://ghcr.io/kobbikobb/charts/mono-api \
      -n mono --create-namespace \
      --set ingress.enabled=true \
      --set ingress.host=mono.example.com

OpenShift, with a Route:

    helm install mono oci://ghcr.io/kobbikobb/charts/mono-api \
      -n mono --create-namespace \
      --set route.enabled=true

Pin a release with `--version X.Y.Z`. Without `route.host`, OpenShift generates
one: `oc -n mono get route mono`.

Enable exactly one of `ingress` or `route`. Key values:
`image.repository`, `image.tag`, `replicaCount`, `service.port`,
`ingress.enabled|className|host|path`, `route.enabled|host|tls.enabled`,
`resources`, `serviceAccount.create`. See `charts/mono-api/values.yaml`.

## Web UI

Run the API and UI together with Docker Compose:

    ./scripts/deploy-docker.sh

The UI is at http://localhost:8080 and proxies `/api` to the API. The Helm chart
deploys the API only.

## Without ingress

    kubectl -n mono port-forward deployment/mono 3000:3000

The API is then at http://localhost:3000.

## Local development

The kind and OpenShift scripts build the image locally, load it into the cluster,
and install the same chart with that image.

### macOS (kind)

    brew install colima docker kind kubectl helm cloud-provider-kind
    colima start
    kind create cluster --name kind

Start the ingress controller in another terminal:

    sudo -E DOCKER_HOST="unix://$HOME/.colima/default/docker.sock" cloud-provider-kind

Then:

    ./scripts/deploy-kind.sh

### Linux (kind)

Install [kind](https://kind.sigs.k8s.io/) v0.33+ (Kubernetes 1.34+ for
`cloud-provider-kind`), kubectl, and Helm. Then:

    kind create cluster --name kind
    ./scripts/deploy-kind.sh

The script starts `cloud-provider-kind` in Docker.

### OpenShift (MicroShift)

Requires Docker, `oc`, and [MINC](https://github.com/minc-org/minc):

    ./scripts/deploy-openshift.sh

No Red Hat pull secret is needed. Stop the cluster with
`minc --provider docker delete`.

### Verify

    ./scripts/curl-api.sh

## Releases

Pushing a `vX.Y.Z` tag publishes the multi-arch image and OCI chart to GHCR.
Pushes to `main` publish `edge`. Make both GHCR packages public after the first
publish.
