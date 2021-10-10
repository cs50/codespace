default: run

build:
	docker build --build-arg VCS_REF="$(shell git rev-parse HEAD)" -t cs50/codespace .

run:
	docker run -it -P --rm --security-opt seccomp=unconfined -v "$(PWD)":/mnt cs50/codespace || true
