Local Kubernetes Deployment (Docker Desktop on Mac/Apple Silicon)

Overview

- This folder contains Kubernetes manifests to run the ESS web app (web UI, API, and SQL Edge database) on Docker Desktop’s built-in Kubernetes.
- Apple Silicon friendly: images and probes adjusted; no architecture pinning is required.

Prerequisites

- Docker Desktop with Kubernetes enabled.
- kubectl configured to the docker-desktop context: `kubectl config use-context docker-desktop`.
- Optional: An ingress controller such as ingress-nginx for host-based routing (`web.localtest.me`, `api.localtest.me`). See Install Ingress below.
- If your images are private on GHCR, create a pull secret named `ghcr-login` in the `app` namespace (see Image Pull Secret below). If images are public, you can remove the `imagePullSecrets` lines or leave them as-is.

What Changed / Why

- Ingress fixed to a valid `networking.k8s.io/v1` manifest with `ingressClassName: nginx` (ingress.yaml).
- API connection string now targets the in-cluster DB service `db` instead of `localhost` (backend.yaml).
- SQL Edge deployment simplified for local use: proper env vars (`MSSQL_SA_PASSWORD`) and probes; removed broken initContainer/ConfigMaps (database.yaml).
- Added readiness/liveness probes for web and api to improve stability.

Deploy Steps

1) Create namespace

   kubectl apply -f namespace.yaml

2) If needed, create image pull secret for GHCR

   kubectl -n app create secret docker-registry ghcr-login \
     --docker-server=ghcr.io \
     --docker-username=<your-gh-username> \
     --docker-password=<your-gh-personal-access-token> \
     --docker-email=<you@example.com>

   - Ensure your PAT has `read:packages` scope.
   - Skip this if your images are public or remove `imagePullSecrets` from the manifests.

3) Deploy components

   kubectl apply -f database.yaml
   kubectl apply -f backend.yaml
   kubectl apply -f frontend.yaml

4) Install Ingress (if not already installed)

   - Install ingress-nginx (example using Helm):

     helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
     helm repo update
     helm install ingress-nginx ingress-nginx/ingress-nginx \
       --namespace ingress-nginx --create-namespace

   - Wait for the LoadBalancer/NodePort to be ready:

     kubectl get pods -n ingress-nginx

5) Apply ingress

   kubectl apply -f ingress.yaml

6) Test access

   - Web: http://web.localtest.me/
   - API: http://api.localtest.me/

Notes

- Database init/restore: the previous initContainer + ConfigMap approach was removed as it could not work (init containers run before the DB is up, and ConfigMaps cannot store large .bak files). For local dev, the DB starts empty. If you need to restore a .bak locally, consider a sidecar job or a one-off `kubectl exec` using a tools image to run `sqlcmd` after the DB is ready.
- Apple Silicon: `mcr.microsoft.com/azure-sql-edge` supports arm64. If the GHCR images aren’t multi-arch, Docker Desktop may emulate amd64; for best performance, publish arm64 variants.
- Without an ingress controller, you can temporarily change Services to `NodePort` and access via `localhost:<nodeport>`.

