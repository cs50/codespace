default: run

build:
	docker build -t cs50/codespace .

rebuild:
	docker build --no-cache -t cs50/codespace .

run:
	docker run -it -P --rm --security-opt seccomp=unconfined -v "$(PWD)":/mnt cs50/codespace bash --login || true
