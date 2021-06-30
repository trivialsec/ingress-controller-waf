SHELL := /bin/bash
-include .env
export $(shell sed 's/=.*//' .env)
NAME_INGRESS = registry.gitlab.com/trivialsec/ingress-controller/nginx
NAME_CERTBOT = registry.gitlab.com/trivialsec/ingress-controller/certbot
.ONESHELL: # Applies to every targets in the file!
.PHONY: help

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

ifndef CI_BUILD_REF
	CI_BUILD_REF = local
endif

setup:
	docker network create trivialsec 2>/dev/null || true
	docker volume create --name=letsencrypt-datadir 2>/dev/null || true
	docker volume create --name=certbot-datadir 2>/dev/null || true

build-ci-ingress: ## Builds ingress controllerimage using docker cli directly for CI
	docker pull registry.gitlab.com/trivialsec/containers-common/waf
	@docker build --compress $(BUILD_ARGS) \
		-t $(NAME_INGRESS):$(CI_BUILD_REF) \
		--cache-from $(NAME_INGRESS):latest \
        --build-arg BUILD_ENV=$(BUILD_ENV) \
		-f conf/nginx/Dockerfile .

build-ci-certbot: ## Builds ingress controllerimage using docker cli directly for CI
	@docker build --compress $(BUILD_ARGS) \
		-t $(NAME_CERTBOT):$(CI_BUILD_REF) \
		--cache-from $(NAME_CERTBOT):latest \
        --build-arg BUILD_ENV=$(BUILD_ENV) \
		-f conf/certbot/Dockerfile .

build-ci: build-ci-ingress build-ci-certbot ## Builds images using docker cli directly for CI

push-tagged: ## Push tagged image
	docker push $(NAME_INGRESS):${CI_BUILD_REF}
	docker push $(NAME_CERTBOT):${CI_BUILD_REF}

push-ci: ## Push latest image using docker cli directly for CI
	docker tag $(NAME_INGRESS):${CI_BUILD_REF} $(NAME_INGRESS):latest
	docker push $(NAME_INGRESS):latest
	docker tag $(NAME_CERTBOT):${CI_BUILD_REF} $(NAME_CERTBOT):latest
	docker push $(NAME_CERTBOT):latest

pull: ## pulls latest image
	docker pull $(NAME_INGRESS):latest
	docker pull $(NAME_CERTBOT):latest

rebuild: down build-ci ## Brings down the stack and builds it anew

docker-login: ## login to docker cli using $DOCKER_USER and $DOCKER_PASSWORD
	@echo $(shell [ -z "${DOCKER_PASSWORD}" ] && echo "DOCKER_PASSWORD missing" )
	@echo ${DOCKER_PASSWORD} | docker login -u ${DOCKER_USER} --password-stdin registry.gitlab.com

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

up: ## Starts latest container images
	docker-compose up -d

down: ## Bring down containers
	@docker-compose down --remove-orphans

gencerts: ## regenerates rootCA and builds the ingress controller / waf
	docker-compose stop ingress
	./bin/gen_cert
	docker-compose build ingress

certs: ## shows trusted cert alias installed
	certutil -d sql:${HOME}/.pki/nssdb -L -n trivialsec

restart: down up ## alias for down && build

tfinstall:
	curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
	sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(shell lsb_release -cs) main"
	sudo apt-get update
	sudo apt-get install -y terraform
	terraform -install-autocomplete || true

init:  ## Runs tf init tf
	cd plans
	terraform init -reconfigure -upgrade=true

plan: init ## Runs tf validate and tf plan
	cd plans
	terraform init -reconfigure -upgrade=true
	terraform validate
	terraform plan -no-color -out=.tfplan
	terraform show --json .tfplan | jq -r '([.resource_changes[]?.change.actions?]|flatten)|{"create":(map(select(.=="create"))|length),"update":(map(select(.=="update"))|length),"delete":(map(select(.=="delete"))|length)}' > tfplan.json

apply: plan ## tf apply -auto-approve -refresh=true
	cd plans
	terraform apply -auto-approve -refresh=true .tfplan

tail-access: ## tail the squid access log in prod
	ssh root@proxy.trivialsec.com tail -f /var/log/squid/access.log

destroy: init ## tf destroy -auto-approve
	cd plans
	terraform validate
	terraform plan -destroy -no-color -out=.tfdestroy
	terraform show --json .tfdestroy | jq -r '([.resource_changes[]?.change.actions?]|flatten)|{"create":(map(select(.=="create"))|length),"update":(map(select(.=="update"))|length),"delete":(map(select(.=="delete"))|length)}' > tfdestroy.json
	terraform apply -auto-approve -destroy .tfdestroy
