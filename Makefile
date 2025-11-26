CLUSTER_NAME ?= lab-eks
KIND_CONFIG  ?= cluster/kind-lab-eks.yaml
NAMESPACE    ?= apps-dev
CHART_PATH   ?= helm/app
RELEASE_NAME ?= demo-app

cluster-up:
	@if ! kind get clusters | grep -q $(CLUSTER_NAME); then \
	  echo ">> creating kind cluster $(CLUSTER_NAME)"; \
	  kind create cluster --name $(CLUSTER_NAME) --config $(KIND_CONFIG); \
	else \
	  echo ">> kind cluster $(CLUSTER_NAME) already exists, skipping"; \
	fi

cluster-down:
	@echo ">> deleting kind cluster $(CLUSTER_NAME) (if it exists)"
	- kind delete cluster --name $(CLUSTER_NAME)

platform-apply:
	@echo ">> applying Terraform platform"
	terraform -chdir=terraform init -upgrade
	terraform -chdir=terraform apply -auto-approve

platform-destroy:
	@echo ">> destroying Terraform platform (if any)"
	- terraform -chdir=terraform destroy -auto-approve

app-deploy:
	@echo ">> deploying Helm release $(RELEASE_NAME) into $(NAMESPACE)"
	helm upgrade --install $(RELEASE_NAME) $(CHART_PATH) \
	  --namespace $(NAMESPACE) \
	  --create-namespace

app-delete:
	@echo ">> uninstalling Helm release $(RELEASE_NAME) from $(NAMESPACE) (if it exists)"
	- helm uninstall $(RELEASE_NAME) -n $(NAMESPACE)

test:
	@echo ">> waiting for rollout of $(RELEASE_NAME) in $(NAMESPACE)"
	kubectl rollout status deploy/$(RELEASE_NAME) -n $(NAMESPACE) --timeout=180s

	@echo ">> smoke test: /readyz"
	kubectl run curl-readyz --rm -i --restart=Never \
	  -n $(NAMESPACE) \
	  --image=curlimages/curl -- \
	  sh -c "curl -sf http://$(RELEASE_NAME):80/readyz"

	@echo ">> smoke test: /"
	kubectl run curl-root --rm -i --restart=Never \
	  -n $(NAMESPACE) \
	  --image=curlimages/curl -- \
	  sh -c "curl -sf http://$(RELEASE_NAME):80/"

ci: cluster-up platform-apply app-deploy test

destroy-all: app-delete platform-destroy cluster-down

cleanup: destroy-all
