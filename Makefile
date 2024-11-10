PD_CONTAINER_MANAGER ?= 'podman'


.PHONY: build
build:
	DATE=$(shell date -u +'%m-%d-%y.%H-%M-%S'); $(PD_CONTAINER_MANAGER) build ./docker/perfect-dark -t docker-caroll:latest -t docker-caroll:$$DATE

.PHONY: clean
clean:
	docker images -a | tail -n +2 | grep docker-caroll | awk '{print $$3}' | xargs docker rmi -f
