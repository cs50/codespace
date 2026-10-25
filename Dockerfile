# Build stage
ARG TAG
FROM cs50/cli:${TAG} AS builder
ARG DEBIAN_FRONTEND=noninteractive


# Unset user
USER root


# Install glibc sources for debugger
# https://github.com/Microsoft/vscode-cpptools/issues/1123#issuecomment-335867997
# Ubuntu's libc6-dbg (from cs50/cli) records source paths relative to the glibc source tree (e.g., ./libio/ioputs.c), so
# gdb finds them via the source search path in etc/gdb/gdbinit.d/glibc.gdb. Sources are the installed libc6's exact
# version, kept compressed in the image and extracted by opt/cs50/bin/postCreateCommand. The archive only carries the
# current version of each source package, so once Ubuntu publishes a newer libc6, cs50/cli must be rebuilt first.
RUN sed --in-place 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/ubuntu.sources && \
    apt update && \
    apt install --no-install-recommends --no-install-suggests --yes \
        dpkg-dev && \
    cd /tmp && \
    version="$(dpkg-query --showformat='${Version}' --show libc6)" && \
    { apt source glibc="$version" || { echo "glibc $version is no longer in the Ubuntu archive; rebuild cs50/cli to pick up the current libc6" >&2; exit 1; }; } && \
    mkdir --parents /usr/src/glibc && \
    tar --create --gzip --file /usr/src/glibc/glibc.tar.gz --directory glibc-*/ . && \
    rm --force --recursive glibc*


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
    git clone https://github.com/cs50/help50.vsix.git && \
    cd help50.vsix && \
    npm install && \
    vsce package && \
    mv help50-0.0.1.vsix /opt/cs50/extensions && \
    cd /tmp && \
    rm --force --recursive help50.vsix && \
    npm uninstall --global vsce yarn


# Final stage
FROM cs50/cli:${TAG}
ENV DOCKER_API_VERSION=1.43


# Unset user
USER root
ARG DEBIAN_FRONTEND=noninteractive


# Copy files from builder
COPY --from=builder /usr/src/glibc /usr/src/glibc
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
        postgresql \
        x11vnc \
        xvfb && \
    apt clean

    
# Install GitHub CLI
RUN (type -p wget >/dev/null || (sudo apt update && sudo apt-get install wget -y)) \
&& sudo mkdir -p -m 755 /etc/apt/keyrings \
&& wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
&& sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
&& sudo apt update \
&& sudo apt install gh -y


# Install Python packages
RUN pip3 install --no-cache-dir \
        black \
        djhtml \
        matplotlib \
        pillow==11.3.0 \
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
