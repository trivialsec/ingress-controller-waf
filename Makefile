SHELL := /bin/bash
-include .env
export $(shell sed 's/=.*//' .env)
.ONESHELL: # Applies to every targets in the file!
.PHONY: help
NAME_INGRESS = registry.gitlab.com/trivialsec/ingress-controller/nginx

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

ifndef CI_BUILD_REF
	CI_BUILD_REF = local
endif

init: ## Runs tf init tf
	cd plans
	terraform init -reconfigure -upgrade=true

deploy: plan apply attach-firewall ## tf plan and apply -auto-approve -refresh=true

plan: init ## Runs tf validate and tf plan
	cd plans
	terraform init -reconfigure -upgrade=true
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

docker-login: ## login to docker cli using $DOCKER_USER and $DOCKER_PASSWORD
	@echo $(shell [ -z "${DOCKER_PASSWORD}" ] && echo "DOCKER_PASSWORD missing" )
	@echo ${DOCKER_PASSWORD} | docker login -u ${DOCKER_USER} --password-stdin registry.gitlab.com

certs: ## shows trusted cert alias installed
	certutil -d sql:${HOME}/.pki/nssdb -L -n trivialsec

gencerts: ## regenerates rootCA and builds the ingress controller cert bundles
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

build: pull ## Builds ingress controller image
	@docker build --compress $(BUILD_ARGS) \
		-t $(NAME_INGRESS):$(CI_BUILD_REF) \
		--cache-from $(NAME_INGRESS):latest \
        --build-arg BUILD_ENV=$(BUILD_ENV) \
		-f Dockerfile .

push-tagged: ## Push tagged image
	docker push -q $(NAME_INGRESS):${CI_BUILD_REF}
	docker push -q $(NAME_CERTBOT):${CI_BUILD_REF}

push: ## Push latest image using docker cli directly for CI
	docker tag $(NAME_INGRESS):${CI_BUILD_REF} $(NAME_INGRESS):latest
	docker push -q $(NAME_INGRESS):latest

pull: ## pulls latest base images
	docker pull -q registry.gitlab.com/trivialsec/containers-common/waf:latest

up: ## Starts latest container images
	docker-compose up -d

down: ## Bring down containers
	docker-compose down --remove-orphans
