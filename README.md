# mono

Demonstrates how to build and publish the artifacts of a small monorepo (a Fastify API and a
React web app) so others can run it on Kubernetes and OpenShift.

- **Images** `ghcr.io/kobbikobb/mono/{api,web}`: non-root, no fixed UID, published by CI.
- **Helm chart** `oci://ghcr.io/kobbikobb/charts/mono` (`charts/mono`): its Ingress becomes a Route on OpenShift.
- **Terraform** (`terraform/`): installs the chart as a customer would.
- **CI**: Playwright e2e on Docker Compose and on kind under restricted pod security.

## Docs

- [Run on the OpenShift Developer Sandbox](docs/openshift.md)
- [Local development on macOS](docs/local-mac.md)
- [Local development on Linux](docs/local-linux.md)

## OpenShift (MicroShift)

Runs the same chart with a Route on a local MicroShift cluster managed by
[MINC](https://github.com/minc-org/minc):

    ./scripts/deploy-openshift.sh
    ./scripts/curl-api.sh

Requires Docker, `oc`, `helm`, and `minc`; no Red Hat pull secret is needed.
Stop the cluster with `minc --provider docker delete`.

Full OpenShift converts an Ingress to a Route, but MicroShift does not, so the
chart has a separate `route.enabled` value.

## Docker Compose

Web at http://localhost:8080:

    ./scripts/deploy-docker.sh
