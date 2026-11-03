# Run on the OpenShift Developer Sandbox

Deploys this app to the free [Developer Sandbox](https://developers.redhat.com/developer-sandbox),
a shared OpenShift cluster from Red Hat. About 15-20 minutes the first time (one timed run: 17).

You need a Red Hat account (free), [`helm`](https://helm.sh/docs/intro/install/) and the
OpenShift CLI `oc` (macOS: `brew install openshift-cli`).

## Steps

1. **Start the sandbox** at https://developers.redhat.com/developer-sandbox
   (**Start your sandbox for free**). It is deleted after 30 days.

2. **Open its console**: on the same page, click **Launch** under
   **Build and deploy your apps to Kubernetes**. Do not click **Create cluster** anywhere;
   those clusters are paid.

3. **Log in from your terminal**: in the console, click your username (top right) →
   **Copy login command** → **Display Token**, and run the `oc login ...` command it shows.
   This switches your kubectl context to the sandbox, so switch back when you are done.
   Check it worked:

        oc project

4. **Pick a web address for the app**:

        HOST="mono-$(oc project -q).$(oc whoami --show-server | sed -E 's#https://api\.(.*):6443#apps.\1#')"
        echo "$HOST"

   *Why?* OpenShift only publishes an app on the internet if you give it an address.
   Without one, the install fails with `ingress.tls needs ingress.host`. The address must end
   with the sandbox's domain (`apps.<cluster>...`), which the command above works out for you.

5. **Install the app** (the images and chart are public, no login needed):

        helm install mono oci://ghcr.io/kobbikobb/charts/mono --wait \
          --set ingress.enabled=true --set ingress.host="$HOST" --set ingress.tls=true

   OpenShift converts the Ingress into a Route that serves HTTPS.

6. **Open it**: go to `https://$HOST`, or check the API:

        curl "https://$HOST/api/users"

## Problems

- `ingress.tls needs ingress.host`: `$HOST` is empty. Redo step 4.
- `ImagePullBackOff`: `oc describe pod`, and check the sandbox can reach ghcr.io.
- A pod is rejected: `oc get events`.

## Clean up

    helm uninstall mono
