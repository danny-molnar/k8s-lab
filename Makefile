CLUSTER_NAME ?= lab-eks
KIND_CONFIG  ?= cluster/kind-lab-eks.yaml
NAMESPACE    ?= apps-dev
CHART_PATH   ?= helm/app
RELEASE_NAME ?= demo-app

.PHONY: cluster-up cluster-down platform-apply platform-destroy app-deploy app-delete test ci destroy-all

cluster-up:
	kind create cluster --name $(CLUSTER_NAME) --config $(KIND_CONFIG)

cluster-down:
	kind delete cluster --name $(CLUSTER_NAME) || true

platform-apply:
	terraform -chdir=terraform init -upgrade
	terraform -chdir=terraform apply -auto-approve

platform-destroy:
	terraform -chdir=terraform destroy -auto-approve || true

app-deploy:
	helm upgrade --install $(RELEASE_NAME) $(CHART_PATH) \
	  --namespace $(NAMESPACE) \
	  --create-namespace

app-delete:
	-helm uninstall $(RELEASE_NAME) -n $(NAMESPACE) || true

test:
	# Wait for deployment to be ready
	kubectl rollout status deploy/$(RELEASE_NAME) -n $(NAMESPACE) --timeout=120s
	# Simple smoke test via a curl pod hitting the service
	kubectl run curl-tester --rm -i --restart=Never \
	  -n $(NAMESPACE) \
	  --image=curlimages/curl -- \
	  curl -sS http://$(RELEASE_NAME):80 || exit 1

ci: cluster-up platform-apply app-deploy test

destroy-all: app-delete platform-destroy cluster-down
