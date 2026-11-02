# Run on the OpenShift Developer Sandbox

The [Developer Sandbox](https://developers.redhat.com/developer-sandbox) is a free,
shared OpenShift cluster from Red Hat. It enforces the restricted security policy
(arbitrary UID, no privileges), so it is a good check that the images and chart work on OpenShift.

Total time: about 15-20 minutes the first time, including installing `oc` and starting the
sandbox (one timed run took 17 minutes).

## Prerequisites

- A Red Hat account (free).
- [`helm`](https://helm.sh/docs/intro/install/) and the OpenShift CLI `oc`
  (macOS: `brew install openshift-cli`).

The images and chart are public on ghcr.io, so no registry login or pull secret is needed.

## Steps

1. Start the sandbox at https://developers.redhat.com/developer-sandbox
   (**Start your sandbox for free**). It is deleted after 30 days.

2. Open its OpenShift console: on the same page, click **Launch** under
   **Build and deploy your apps to Kubernetes**. Do not use **Create cluster** in the
   Red Hat Hybrid Cloud Console; those are paid clusters. The sandbox console is at
   `console-openshift-console.apps.<cluster>`.

3. In that console, click your username (top right) → **Copy login command** →
   **Display Token**, and run the `oc login` command it shows:

        oc login --token=sha256~... --server=https://api.<cluster>:6443

   This switches your kubectl context to the sandbox, so switch back afterwards
   (`kubectl config use-context <name>`). Check you are in your project (`<username>-dev`):

        oc project

4. Choose a hostname under the sandbox's apps domain. The chart needs a host to create a Route:

        HOST="mono-$(oc project -q).$(oc whoami --show-server | sed -E 's#https://api\.(.*):6443#apps.\1#')"
        echo "$HOST"

5. Install the published chart and wait for the pods:

        helm install mono oci://ghcr.io/kobbikobb/charts/mono --wait \
          --set ingress.enabled=true --set ingress.host="$HOST" --set ingress.tls=true

   OpenShift converts the Ingress into a Route that serves HTTPS.

6. Open `https://$HOST` and check the API:

        curl "https://$HOST/api/users"

## Troubleshooting

- `ImagePullBackOff`: `oc describe pod`; check the sandbox can reach ghcr.io.
- Pod rejected by a security policy: `oc get events`; the containers must run as non-root
  without fixed UIDs.
- Route missing: `oc get ingress,route`; the Ingress needs `ingress.host` to become a Route.

## Clean up

    helm uninstall mono
