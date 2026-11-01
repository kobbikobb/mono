# Run on the OpenShift Developer Sandbox

The [Developer Sandbox](https://developers.redhat.com/developer-sandbox) is a free,
shared OpenShift cluster from Red Hat. It enforces the restricted security policy
(arbitrary UID, no privileges), so it is a good check that the images and chart work on OpenShift.

## Prerequisites

- A Red Hat account (free).
- [`oc`](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/cli_tools/openshift-cli-oc) and [`helm`](https://helm.sh/docs/intro/install/) installed.

The images and chart are public on ghcr.io, so no registry login or pull secret is needed.

Total time: about 10 minutes, of which sign-up and sandbox start (step 1) take about 8
and the install (steps 2-7) about 2. If you already have a sandbox, it is about 2 minutes.

## Steps

1. Sign up at https://developers.redhat.com/developer-sandbox and start the OpenShift sandbox.
   The sandbox sleeps after inactivity and is deleted after 30 days.

2. Open the web console, click your username (top right) → **Copy login command** →
   **Display Token**, and run the `oc login --token=... --server=...` command it shows:

        oc login --token=sha256~... --server=https://api.<cluster>:6443

3. Check you are in your project (named `<username>-dev`):

        oc project

4. Choose a hostname under the sandbox's apps domain (derived from the cluster API URL):

        HOST="mono-$(oc project -q).$(oc whoami --show-server | sed -E 's#https://api\.(.*):6443#apps.\1#')"
        echo "$HOST"

5. Install the published chart:

        helm install mono oci://ghcr.io/kobbikobb/charts/mono \
          --set ingress.enabled=true --set ingress.host="$HOST"

   OpenShift converts the Ingress rule for that host into a Route.

6. Wait for the pods:

        oc rollout status deployment/mono-api deployment/mono-web

7. Open the app at `http://$HOST` and check the API:

        curl "http://$HOST/api/users"

## Troubleshooting

- `ImagePullBackOff`: check the image name and that the sandbox can reach ghcr.io (`oc describe pod`).
- Pod rejected by a security policy: check `oc get events`; the containers must run as non-root
  without fixed UIDs.
- Route missing: `oc get ingress,route`; the Ingress needs a host (`ingress.host`) to become a Route.

## Clean up

    helm uninstall mono
