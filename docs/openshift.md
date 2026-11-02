# Run on the OpenShift Developer Sandbox

The [Developer Sandbox](https://developers.redhat.com/developer-sandbox) is a free,
shared OpenShift cluster from Red Hat. It enforces the restricted security policy
(arbitrary UID, no privileges), so it is a good check that the images and chart work on OpenShift.

Total time: about 15-20 minutes the first time, including installing `oc` and starting the
sandbox (one timed run took 17 minutes).

## Prerequisites

- A Red Hat account (free).
- [`oc`](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/cli_tools/openshift-cli-oc) and [`helm`](https://helm.sh/docs/intro/install/) installed.

The images and chart are public on ghcr.io, so no registry login or pull secret is needed.

## Steps

1. Sign up at https://developers.redhat.com/developer-sandbox and start the OpenShift sandbox.
   The sandbox sleeps after inactivity and is deleted after 30 days.

2. Open the sandbox's OpenShift web console. On the
   [Developer Sandbox page](https://developers.redhat.com/developer-sandbox), click **Launch**
   under **Build and deploy your apps to Kubernetes**. The Red Hat Hybrid Cloud Console
   (console.redhat.com, with your name and Org ID) is a different site and has no sandbox login
   command. The sandbox console is at `console-openshift-console.apps.<cluster>`.

3. In the OpenShift console, click your username (top right) → **Copy login command** →
   **Display Token**, and run the `oc login --token=... --server=...` command it shows:

        oc login --token=sha256~... --server=https://api.<cluster>:6443

4. Check you are in your project (named `<username>-dev`):

        oc project

5. Choose a hostname under the sandbox's apps domain (derived from the cluster API URL):

        HOST="mono-$(oc project -q).$(oc whoami --show-server | sed -E 's#https://api\.(.*):6443#apps.\1#')"
        echo "$HOST"

6. Install the published chart:

        helm install mono oci://ghcr.io/kobbikobb/charts/mono \
          --set ingress.enabled=true --set ingress.host="$HOST"

   OpenShift converts the Ingress rule for that host into a Route.

7. Wait for the pods:

        oc rollout status deployment/mono-api deployment/mono-web

8. Open the app at `http://$HOST` and check the API:

        curl "http://$HOST/api/users"

## Troubleshooting

- `ImagePullBackOff`: check the image name and that the sandbox can reach ghcr.io (`oc describe pod`).
- Pod rejected by a security policy: check `oc get events`; the containers must run as non-root
  without fixed UIDs.
- Route missing: `oc get ingress,route`; the Ingress needs a host (`ingress.host`) to become a Route.

## Clean up

    helm uninstall mono
