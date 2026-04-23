RUNTIME := $(shell which docker 2>/dev/null || which podman 2>/dev/null)
COMPOSE := $(shell docker compose version > /dev/null 2>&1 && echo 'docker compose')

ifeq ($(COMPOSE),)
COMPOSE := $(shell podman-compose version > /dev/null 2>&1 && echo 'podman-compose')
endif

ifeq ($(COMPOSE),)
$(error Neither 'docker compose' nor 'podman-compose' is available)
endif

.PHONY: up exec down

up:
	$(COMPOSE) up --build -d

exec-spire-server:
	$(RUNTIME) exec -it spire-server sh

exec-spire-agent:
	$(RUNTIME) exec -it spire-agent sh

exec-openbao:
	$(RUNTIME) exec -it openbao sh

down:
	$(COMPOSE) down -v
