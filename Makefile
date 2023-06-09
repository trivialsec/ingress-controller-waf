SHELL := /bin/bash
-include .env
export $(shell sed 's/=.*//' .env)
.ONESHELL: # Applies to every targets in the file!
.PHONY: help
BASE_NAME = registry.gitlab.com/trivialsec/ingress-controller

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

ifndef CI_BUILD_REF
	CI_BUILD_REF = local
endif

init: ## Runs tf init tf
	cd plans
	terraform init -reconfigure -upgrade=true

output:
	cd plans
	terraform output projecthoneypot_key

deploy: plan apply attach-firewall ## tf plan and apply -auto-approve -refresh=true

plan: init ## Runs tf validate and tf plan
	cd plans
	terraform validate
	terraform plan -no-color -out=.tfplan
	terraform show --json .tfplan | jq -r '([.resource_changes[]?.change.actions?]|flatten)|{"create":(map(select(.=="create"))|length),"update":(map(select(.=="update"))|length),"delete":(map(select(.=="delete"))|length)}' > tfplan.json

apply: ## tf apply -auto-approve -refresh=true
	cd plans
	terraform apply -auto-approve -refresh=true .tfplan

destroy: init ## tf destroy -auto-approve
	cd plans
	terraform validate
	terraform plan -destroy -no-color -out=.tfdestroy
	terraform show --json .tfdestroy | jq -r '([.resource_changes[]?.change.actions?]|flatten)|{"create":(map(select(.=="create"))|length),"update":(map(select(.=="update"))|length),"delete":(map(select(.=="delete"))|length)}' > tfdestroy.json
	terraform apply -auto-approve -destroy .tfdestroy

attach-firewall:
	curl -s -H "Content-Type: application/json" \
		-H "Authorization: Bearer ${TF_VAR_linode_token}" \
		-X POST -d '{"type": "linode", "id": $(shell curl -s -H "Authorization: Bearer ${TF_VAR_linode_token}" https://api.linode.com/v4/linode/instances | jq -r '.data[] | select(.label=="prd-ingress.trivialsec.com") | .id')}' \
		https://api.linode.com/v4/networking/firewalls/${LINODE_FIREWALL}/devices

#####################
# Development Only
#####################
setup: ## Creates docker networks and volumes
	docker network create trivialsec 2>/dev/null || true

tfinstall:
	curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
	sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(shell lsb_release -cs) main"
	sudo apt-get update
	sudo apt-get install -y terraform
	terraform -install-autocomplete || true

docker-login: ## login to docker cli using $GITLAB_USER and $GITLAB_PAT
	@echo $(shell [ -z "${GITLAB_PAT}" ] && echo "GITLAB_PAT missing" )
	@echo ${GITLAB_PAT} | docker login -u ${GITLAB_USER} --password-stdin registry.gitlab.com

certs: ## shows trusted cert alias installed
	certutil -d sql:${HOME}/.pki/nssdb -L -n trivialsec

gencerts: ## regenerates rootCA and builds the ingress controller cert bundles
	mkdir -p .${BUILD_ENV}/cacert
	./bin/gen_cert

gen-dhparams: ## regenerates dhparam.pem
	openssl dhparam -out .production/ssl-dhparams.pem 4096

docker-clean: ## quick docker environment cleanup
	docker rmi $(docker images -qaf "dangling=true")
	yes | docker system prune
	sudo service docker restart

docker-purge: ## thorough docker environment cleanup
	docker rmi $(docker images -qa)
	yes | docker system prune
	sudo service docker stop
	sudo rm -rf /tmp/docker.backup/
	sudo cp -Pfr /var/lib/docker /tmp/docker.backup
	sudo rm -rf /var/lib/docker
	sudo service docker start

build-base: ## Builds ingress controller image
	@docker build --compress $(BUILD_ARGS) \
		-t $(BASE_NAME)/nginx:$(CI_BUILD_REF) \
		--cache-from $(BASE_NAME)/nginx:latest \
        --build-arg BUILD_ENV=$(BUILD_ENV) \
		--build-arg NGINX_VERSION=$(NGINX_VERSION) \
		--build-arg GEO_DB_RELEASE=$(GEO_DB_RELEASE) \
		--build-arg MODSEC_BRANCH=$(MODSEC_BRANCH) \
		--build-arg OWASP_BRANCH=$(OWASP_BRANCH) \
		-f base/Dockerfile .

buildnc: build-base ## Builds ingress controller image with --no-cache
    @docker build --compress $(BUILD_ARGS) \
		-t $(BASE_NAME)/waf:$(CI_BUILD_REF) \
		--no-cache \
        --build-arg BUILD_ENV=$(BUILD_ENV) \
		-f Dockerfile .

build: pull-base ## Builds ingress controller image
	@docker build --compress $(BUILD_ARGS) \
		--cache-from $(BASE_NAME)/waf:latest \
		-t $(BASE_NAME)/waf:$(CI_BUILD_REF) \
        --build-arg BUILD_ENV=$(BUILD_ENV) \
		-f Dockerfile .

push-tagged: ## Push tagged image
	docker push -q $(BASE_NAME)/waf:${CI_BUILD_REF}

push-base: ## Push latest image using docker cli directly for CI
	docker tag $(BASE_NAME)/nginx:${CI_BUILD_REF} $(BASE_NAME)/nginx:latest
	docker push -q $(BASE_NAME)/nginx:latest

push: ## Push latest image using docker cli directly for CI
	docker tag $(BASE_NAME)/waf:${CI_BUILD_REF} $(BASE_NAME)/waf:latest
	docker push -q $(BASE_NAME)/waf:latest

pull: ## pulls latest latest images
	docker pull -q $(BASE_NAME)/waf:latest

pull-base: ## pulls latest base images
	docker pull -q $(BASE_NAME)/nginx:latest

up: ## Starts latest container images
	docker-compose up -d

down: ## Bring down containers
	docker-compose down --remove-orphans
