.PHONY: build
build:
	DATE=$(shell date -u +'%m-%d-%y.%H-%M-%S'); docker build ./docker/perfect-dark -t docker-caroll:latest -t docker-caroll:$$DATE --platform amd64

.PHONY: clean
clean:
	docker images -a | tail -n +2 | grep docker-caroll | awk '{print $$3}' | xargs docker rmi -f
