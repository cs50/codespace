FROM cs50/cli:minimal
ARG DEBIAN_FRONTEND=noninteractive


# Unset user
USER root


# Install Ubuntu packages
RUN apt update && \
    apt install --yes \
        jq


# For temporarily removing ACLs via opt/cs50/bin/postCreateCommand
# https://github.community/t/bug-umask-does-not-seem-to-be-respected/129638/9
RUN apt update && \
    apt install acl


# Install Python packages
RUN pip3 install git+https://github.com/cs50/submit50@classroom


# Install VS Code extensions
RUN mkdir -p /opt/cs50/extensions && \
    cd /tmp && \
    git clone https://github.com/cs50/cs50.vsix.git && \
    cd cs50.vsix && \
    npm install && \
    ./node_modules/vsce/out/vsce package && \
    mv cs50-0.0.1.vsix /opt/cs50/extensions && \
    pip install python-clients/cs50vsix-client/ && \
    cd /tmp && \
    rm -rf cs50.vsix && \
    git clone https://github.com/cs50/ddb50.vsix.git && \
    cd ddb50.vsix && \
    npm install && \
    ./node_modules/vsce/out/vsce package && \
    mv ddb50-0.0.1.vsix /opt/cs50/extensions && \
    cd /tmp && \
    rm -rf ddb50.vsix


# Copy files to image
COPY ./etc /etc
COPY ./opt /opt
RUN chmod a+rx /opt/cs50/bin/*


# Temporary workaround for https://github.com/cs50/code.cs50.io/issues/19
RUN echo "if [ -z \"\$_PROFILE_D\" ] ; then for i in /etc/profile.d/*.sh; do . \"\$i\"; done; export _PROFILE_D=1; fi" >> /etc/bash.bashrc


# Install glibc sources for debugger
# https://github.com/Microsoft/vscode-cpptools/issues/1123#issuecomment-335867997
RUN echo "deb-src http://archive.ubuntu.com/ubuntu/ focal main restricted" > /etc/apt/sources.list.d/_.list && \
    apt update && \
    cd /tmp && \
    apt source glibc && \
    rm -f /etc/apt/sources.list.d/_.list && \
    apt update && \
    mkdir -p /opt/cs50/src/glibc-eX1tMB && \
    mv glibc* /opt/cs50/src/glibc-eX1tMB && \
    cd /opt/cs50/src/glibc-eX1tMB \
    rm -rf *.tar.xz \
    rm -rf *.dsc


# Set user
USER ubuntu
