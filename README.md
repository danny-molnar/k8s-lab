# k8s-lab

Local Kubernetes lab that brings up a kind cluster, installs platform dependencies with Terraform, and deploys a demo Helm chart. CI runs the same flow in GitHub Actions for every push/PR.

## Layout
- Makefile: entrypoints for cluster lifecycle, platform install, app deploy, testing, and cleanup.
- cluster/kind-lab-eks.yaml: kind cluster definition with 8080/8443 host ports mapped to the ingress controller.
- terraform/: creates namespaces and installs ingress-nginx, metrics-server, and kube-prometheus-stack via Helm.
- helm/app/: demo nginx app chart (Deployment, Service, Ingress, HPA, ConfigMap, Secret, helpers).
- .github/workflows/kind-e2e.yaml: e2e pipeline that runs make ci inside kind.

## Prerequisites
- Docker (for kind nodes)
- kind >= 0.23
- kubectl + kubeconfig at ~/.kube/config with context `kind-lab-eks` (created by make cluster-up)
- Helm 3
- Terraform >= 1.5
- make
- Free local ports 8080/8443 (forwarded to the ingress controller)

## Quickstart
```sh
# Create the kind cluster
make cluster-up

# Install platform dependencies (namespaces, ingress, metrics, monitoring)
make platform-apply

# Deploy the demo app chart into apps-dev
make app-deploy
```

## Inspect and access
```sh
kubectl get pods -n apps-dev
kubectl get ingress -n apps-dev

# Access through ingress (host resolves to 127.0.0.1)
curl -H "Host: demo.localtest.me" http://localhost:8080/
```
- Ingress is backed by ingress-nginx (NodePort) with host ports mapped to 8080/8443 by the kind config.

## Smoke test and CI
- make test waits for the Deployment rollout and runs a curl pod against the service.
- make ci runs cluster creation, platform install, app deploy, and the smoke test (used in .github/workflows/kind-e2e.yaml).
- make cleanup tears everything down (used as the final CI step).

## Customizing the app chart
- Edit helm/app/values.yaml to change the nginx image tag, ingress host/path, env values, secrets, resources, or HPA settings.
- Override values at deploy time if needed:
```sh
helm upgrade --install demo-app helm/app -n apps-dev --create-namespace --set image.repository=myrepo/web --set ingress.host=myapp.localtest.me
```

## Cleanup
```sh
make destroy-all  # uninstall release, destroy platform components, and delete the kind cluster
```
