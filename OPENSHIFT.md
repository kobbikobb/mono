# Run on the OpenShift Developer Sandbox

The [Developer Sandbox](https://developers.redhat.com/developer-sandbox) is a free,
shared OpenShift cluster from Red Hat. It enforces the restricted security policy
(arbitrary UID, no privileges), so it is a good check that the images and chart work on OpenShift.

## Prerequisites

- A Red Hat account (free).
- [`oc`](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/cli_tools/openshift-cli-oc) and [`helm`](https://helm.sh/docs/intro/install/) installed.
- The images `ghcr.io/kobbikobb/mono/api` and `ghcr.io/kobbikobb/mono/web` must be **public**
  (GitHub package settings → Change visibility). Packages are private by default.

## Steps

1. Sign up at https://developers.redhat.com/developer-sandbox and start the OpenShift sandbox.
   The sandbox sleeps after inactivity and is deleted after 30 days.

2. Open the web console, click your username (top right) → **Copy login command** →
   **Display Token**, and run the `oc login --token=... --server=...` command it shows:

        oc login --token=sha256~... --server=https://api.<cluster>:6443

3. Check you are in your project (named `<username>-dev`):

        oc project

4. Install the chart from this repo:

        helm install mono ./charts/mono --set ingress.enabled=true

   OpenShift converts the Ingress into a Route and generates a hostname.

5. Wait for the pods:

        oc rollout status deployment/mono-api deployment/mono-web

6. Open the app:

        echo "http://$(oc get route -o jsonpath='{.items[0].spec.host}')"

7. Check the API through the same URL:

        curl "http://$(oc get route -o jsonpath='{.items[0].spec.host}')/api/users"

## Troubleshooting

- `ImagePullBackOff`: the ghcr.io packages are still private.
- Pod rejected by a security policy: check `oc get events`; the containers must run as non-root
  without fixed UIDs.
- Route missing: `oc get ingress,route` and make sure `ingress.enabled=true`.

## Clean up

    helm uninstall mono
