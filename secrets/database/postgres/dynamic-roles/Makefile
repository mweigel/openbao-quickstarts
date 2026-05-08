DOCKER_COMPOSE := $(shell docker compose version > /dev/null 2>&1 && echo 'docker compose')
PODMAN_COMPOSE := $(shell podman-compose version > /dev/null 2>&1 && echo 'podman-compose')

ifeq ($(DOCKER_COMPOSE),docker compose)
COMPOSE := $(DOCKER_COMPOSE)
RUNTIME := docker
else ifeq ($(PODMAN_COMPOSE),podman-compose)
COMPOSE := $(PODMAN_COMPOSE)
RUNTIME := podman
else
$(error Neither 'docker compose' nor 'podman-compose' is available)
endif

.PHONY: up exec-openbao exec-postgres exec-client down

up:
	$(COMPOSE) up --build -d

exec-openbao:
	$(RUNTIME) exec -it openbao sh

exec-postgres:
	$(RUNTIME) exec -it postgres sh

exec-client:
	$(RUNTIME) exec -it client sh

down:
	$(COMPOSE) down -v