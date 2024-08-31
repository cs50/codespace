# Build stage
ARG TAG
FROM cs50/cli:${TAG} AS builder
ARG DEBIAN_FRONTEND=noninteractive


# Unset user
USER root


# Install glibc sources for debugger
# https://github.com/Microsoft/vscode-cpptools/issues/1123#issuecomment-335867997
RUN echo "deb-src http://archive.ubuntu.com/ubuntu/ jammy main restricted" > /etc/apt/sources.list.d/_.list && \
    apt update && \
    apt install --no-install-recommends --no-install-suggests --yes \
        dpkg-dev && \
    cd /tmp && \
    apt source glibc && \
    rm --force --recursive *.dsc *.tar.* && \
    mkdir --parents /build/glibc-sMfBJT && \
    tar --create --gzip --file /build/glibc-sMfBJT/glibc.tar.gz glibc*


# Install BFG
RUN wget https://repo1.maven.org/maven2/com/madgag/bfg/1.14.0/bfg-1.14.0.jar -P /opt/share


# Install Lua 5.x
# https://www.lua.org/download.html
RUN cd /tmp && \
    curl --remote-name https://www.lua.org/ftp/lua-5.4.7.tar.gz && \
    tar xzf lua-5.4.7.tar.gz && \
    rm --force lua-5.4.7.tar.gz && \
    cd lua-5.4.7 && \
    make all install && \
    cd .. && \
    rm --force --recursive /tmp/lua-5.4.7


# Install noVNC (VNC client)
RUN cd /tmp && \
    curl --location --remote-name https://github.com/novnc/noVNC/archive/refs/tags/v1.5.0.zip && \
    unzip v1.5.0.zip && \
    rm --force v1.5.0.zip && \
    cd noVNC-1.5.0/utils && \
    curl --location --remote-name https://github.com/novnc/websockify/archive/refs/heads/master.tar.gz && \
    tar xzf master.tar.gz && \
    mv websockify-master websockify && \
    rm --force master.tar.gz && \
    cd ../.. && \
    mv noVNC-1.5.0 /opt/noVNC


# Install VS Code extensions
RUN npm install --global @vscode/vsce yarn && \
    mkdir --parents /opt/cs50/extensions && \
    cd /tmp && \
    git clone https://github.com/cs50/explain50.vsix.git && \
    cd explain50.vsix && \
    npm install && \
    vsce package && \
    mv explain50-1.0.0.vsix /opt/cs50/extensions && \
    cd /tmp && \
    rm --force --recursive explain50.vsix && \
    git clone https://github.com/cs50/cs50.vsix.git && \
    cd cs50.vsix && \
    npm install && \
    vsce package && \
    mv cs50-0.0.1.vsix /opt/cs50/extensions && \
    mv python-clients/cs50vsix-client /opt/cs50/extensions && \
    cd /tmp && \
    rm --force --recursive cs50.vsix && \
    git clone https://github.com/cs50/ddb50.vsix.git && \
    cd ddb50.vsix && \
    npm install && \
    vsce package && \
    mv ddb50-2.0.0.vsix /opt/cs50/extensions && \
    cd /tmp && \
    rm --force --recursive ddb50.vsix && \
    git clone https://github.com/cs50/phpliteadmin.vsix.git && \
    cd phpliteadmin.vsix && \
    npm install && \
    vsce package && \
    mv phpliteadmin-0.0.1.vsix /opt/cs50/extensions && \
    cd /tmp && \
    rm --force --recursive phpliteadmin.vsix && \
    git clone https://github.com/cs50/style50.vsix.git && \
    cd style50.vsix && \
    npm install && \
    vsce package && \
    mv style50-0.0.1.vsix /opt/cs50/extensions && \
    cd /tmp && \
    rm --force --recursive style50.vsix && \
    git clone https://github.com/cs50/design50.vsix.git && \
    cd design50.vsix && \
    npm install && \
    vsce package && \
    mv design50-1.0.0.vsix /opt/cs50/extensions && \
    cd /tmp && \
    rm --force --recursive design50.vsix && \
    npm uninstall --global vsce yarn


# Final stage
FROM cs50/cli:${TAG}


# Unset user
USER root
ARG DEBIAN_FRONTEND=noninteractive


# Copy files from builder
COPY --from=builder /build /build
COPY --from=builder /opt /opt
COPY --from=builder /usr/local /usr/local
RUN pip3 install --no-cache-dir /opt/cs50/extensions/cs50vsix-client/ && \
    rm --force --recursive /opt/cs50/extensions/cs50vsix-client


# Set virtual display
ENV DISPLAY=":0"


# Install Ubuntu packages
# Install acl for temporarily removing ACLs via opt/cs50/bin/postCreateCommand
# https://github.community/t/bug-umask-does-not-seem-to-be-respected/129638/9
RUN apt update && \
    apt install --no-install-recommends --no-install-suggests --yes \
        acl \
        dwarfdump \
        jq \
        openbox \
        mysql-client \
        php-cli \
        php-mbstring \
        php-sqlite3 \
        x11vnc \
        xvfb && \
    apt clean


# Install Python packages
RUN pip3 install --no-cache-dir \
        black \
        djhtml \
        inflect==7.0.0 \
        matplotlib \
        "pydantic<2" \
        pytz \
        setuptools


# Copy files to image
COPY ./etc /etc
COPY ./opt /opt
RUN chmod a+rx /opt/cs50/bin/* && \
    chmod a+rx /opt/cs50/phpliteadmin/bin/phpliteadmin && \
    ln --symbolic /opt/cs50/phpliteadmin/bin/phpliteadmin /opt/cs50/bin/phpliteadmin


# Enforce login shell
RUN echo "\nshopt -q login_shell || exec bash --login -i" >> /etc/bash.bashrc


# Set user
USER ubuntu
