FROM ubuntu:20.04
LABEL maintainer="sysadmins@cs50.harvard.edu"
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install --yes \
        bash-completion \
        clang \
        coreutils `# for fold` \
        curl \
        gdb \
        git \
        jq \
        make \
        psmisc `# for fuser` \
        python3 \
        python3-pip \
        sqlite3 \
        sudo \
        wget \
        zip

# Node.js 14.x and npm
RUN curl -fsSL https://deb.nodesource.com/setup_14.x | bash - && \
    apt-get install --yes nodejs

# CS50 apt packages
RUN curl --silent https://packagecloud.io/install/repositories/cs50/repo/script.deb.sh | bash && \
    apt-get install --yes \
        libcs50

RUN pip3 install --upgrade pip
RUN pip3 install \
    check50 \
    cs50 \
    Flask \
    Flask-Session \
    pylint

RUN npm install --global http-server

COPY files/ /
RUN chmod a+rx /opt/cs50/bin/*

ENV PATH="/opt/cs50/bin:/opt/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
RUN sed -i "s|^PATH=.*|PATH=$PATH|" /etc/environment

# Add user ubuntu
RUN useradd --home-dir /home/ubuntu --shell /bin/bash ubuntu && \
    umask 0077 && \
    mkdir -p /home/ubuntu && \
    chown -R ubuntu:ubuntu /home/ubuntu

# Add user ubuntu to sudoers
RUN echo "\n# CS50 Codespace" >> /etc/sudoers
RUN echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN echo "Defaults umask_override" >> /etc/sudoers
RUN echo "Defaults umask=0022" >> /etc/sudoers
RUN sed -e "s|^Defaults\tsecure_path=.*|Defaults\t!secure_path|" -i /etc/sudoers

USER ubuntu
WORKDIR /home/ubuntu
