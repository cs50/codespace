default: run

build:
	docker build -t cs50/cli:bookdown .

rebuild:
	docker build --no-cache -t cs50/cli:bookdown .

run:
	docker run -it -P --rm --security-opt seccomp=unconfined -v "$(PWD)":/mnt -w /mnt cs50/cli:bookdown
