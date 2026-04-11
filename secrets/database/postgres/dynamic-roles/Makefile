COMPOSE := $(shell docker compose version > /dev/null 2>&1 && echo 'docker compose')

ifeq ($(COMPOSE),)
COMPOSE := $(shell podman-compose version > /dev/null 2>&1 && echo 'podman-compose')
endif

ifeq ($(COMPOSE),)
$(error Neither 'docker compose' nor 'podman-compose' is available)
endif

.PHONY: up down

up:
	$(COMPOSE) up

down:
	$(COMPOSE) down
