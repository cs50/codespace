FROM cs50/cli
ARG DEBIAN_FRONTEND=noninteractive
ARG VCS_REF


# Unset user
USER root


# Install Ubuntu packages
RUN apt update && \
    apt install --no-install-recommends --yes \
        jq \
        php-cli \
        php-mbstring \
        php-sqlite3


# For temporarily removing ACLs via opt/cs50/bin/postCreateCommand
# https://github.community/t/bug-umask-does-not-seem-to-be-respected/129638/9
RUN apt update && \
    apt install acl


# Install Python packages
RUN pip3 install git+https://github.com/cs50/submit50@classroom


# Install VS Code extensions
RUN mkdir --parents /opt/cs50/extensions && \
    cd /tmp && \
    git clone https://github.com/cs50/cs50.vsix.git && \
    cd cs50.vsix && \
    npm install && \
    ./node_modules/vsce/out/vsce package && \
    mv cs50-0.0.1.vsix /opt/cs50/extensions && \
    pip install python-clients/cs50vsix-client/ && \
    cd /tmp && \
    rm --force --recursive cs50.vsix && \
    git clone https://github.com/cs50/ddb50.vsix.git && \
    cd ddb50.vsix && \
    npm install && \
    ./node_modules/vsce/out/vsce package && \
    mv ddb50-0.0.1.vsix /opt/cs50/extensions && \
    cd /tmp && \
    rm --force --recursive ddb50.vsix && \
    git clone https://github.com/cs50/phpliteadmin.vsix.git && \
    cd phpliteadmin.vsix && \
    npm install && \
    ./node_modules/vsce/out/vsce package && \
    mv phpliteadmin-0.0.1.vsix /opt/cs50/extensions && \
    cd /tmp && \
    rm --force --recursive phpliteadmin.vsix


# Copy files to image
COPY ./etc /etc
COPY ./opt /opt
RUN chmod a+rx /opt/cs50/bin/*
RUN chmod a+rx /opt/cs50/phpliteadmin/bin/phpliteadmin
RUN ln --symbolic /opt/cs50/phpliteadmin/bin/phpliteadmin /opt/cs50/bin/phpliteadmin


# Temporary workaround for https://github.com/cs50/code.cs50.io/issues/19
RUN echo "if [ -z \"\$_PROFILE_D\" ] ; then for i in /etc/profile.d/*.sh; do . \"\$i\"; done; export _PROFILE_D=1; fi" >> /etc/bash.bashrc


# Install glibc sources for debugger
# https://github.com/Microsoft/vscode-cpptools/issues/1123#issuecomment-335867997
RUN echo "deb-src http://archive.ubuntu.com/ubuntu/ focal main restricted" > /etc/apt/sources.list.d/_.list && \
    apt update && \
    cd /tmp && \
    apt source glibc && \
    rm --force /etc/apt/sources.list.d/_.list && \
    apt update && \
    mkdir --parents /opt/cs50/src/glibc-eX1tMB && \
    mv glibc* /opt/cs50/src/glibc-eX1tMB && \
    cd /opt/cs50/src/glibc-eX1tMB \
    rm --force --recursive *.tar.xz \
    rm --force --recursive *.dsc


# Latest version
RUN echo "$VCS_REF" > /etc/issue


# Set user
USER ubuntu
