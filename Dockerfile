# Build stage
FROM cs50/cli:amd64 as builder
ARG DEBIAN_FRONTEND=noninteractive


# Unset user
USER root


# Install glibc sources for debugger
# https://github.com/Microsoft/vscode-cpptools/issues/1123#issuecomment-335867997
RUN echo "deb-src http://archive.ubuntu.com/ubuntu/ jammy main restricted" > /etc/apt/sources.list.d/_.list && \
    apt update && \
    apt install --no-install-recommends --no-install-suggests --yes dpkg-dev && \
    cd /tmp && \
    apt source glibc && \
    rm --force --recursive *.dsc *.tar.* && \
    mkdir --parents /build/glibc-sMfBJT && \
    tar --create --gzip --file /build/glibc-sMfBJT/glibc.tar.gz glibc*


# Install BFG
RUN wget https://repo1.maven.org/maven2/com/madgag/bfg/1.14.0/bfg-1.14.0.jar -P /opt/share


# Install Lua 5.x
RUN wget http://www.lua.org/ftp/lua-5.4.4.tar.gz -P/tmp && \
    cd /tmp && \
    tar zxf lua-5.4.4.tar.gz && \
    cd lua-5.4.4 && \
    make all test install && \
    cd /tmp && \
    rm -rf /tmp/lua-5.4.4*


# Install noVNC (VNC client)
RUN wget https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.zip -P/tmp && \
    unzip /tmp/v1.4.0.zip -d /tmp && \
    mv /tmp/noVNC-1.4.0 /opt/noVNC && \
    rm -rf /tmp/noVNC-1.4.0 /tmp/v1.4.0.zip && \
    chown -R ubuntu:ubuntu /opt/noVNC


# Install RStudio
# https://posit.co/download/rstudio-server/
# https://github.com/rstudio/rstudio/tags
# https://cran.rstudio.com/bin/linux/ubuntu/
RUN apt update && \
    apt install --no-install-recommends --no-install-suggests --yes \
        gdebi-core \
        software-properties-common && \
    cd /tmp && \
    if [ $(uname -m) = "x86_64" ]; then ARCH="amd64"; else ARCH="arm64"; fi && \
    curl --remote-name https://s3.amazonaws.com/rstudio-ide-build/server/jammy/${ARCH}/rstudio-server-2023.03.3-547-${ARCH}.deb && \
    gdebi --non-interactive rstudio-server-2023.03.3-547-${ARCH}.deb && \
    add-apt-repository --yes ppa:c2d4u.team/c2d4u4.0+ && \
    apt update && \
    apt install --no-install-recommends --no-install-suggests --yes r-cran-tidyverse


# Install VS Code extensions
RUN npm install -g @vscode/vsce yarn && \
    mkdir --parents /opt/cs50/extensions && \
    cd /tmp && \
    git clone https://github.com/cs50/explain50.vsix.git && \
    cd explain50.vsix && \
    npm install && \
    vsce package && \
    mv explain50-1.0.0.vsix /opt/cs50/extensions && \
    cd /tmp && \
    rm -rf explain50.vsix && \
    git clone https://github.com/cs50/cs50.vsix.git && \
    cd cs50.vsix && \
    npm install && \
    vsce package && \
    mv cs50-0.0.1.vsix /opt/cs50/extensions && \
    mv python-clients/cs50vsix-client /opt/cs50/extensions && \
    cd /tmp && \
    rm -rf cs50.vsix && \
    git clone https://github.com/cs50/ddb50.vsix.git && \
    cd ddb50.vsix && \
    npm install && \
    vsce package && \
    mv ddb50-2.0.0.vsix /opt/cs50/extensions && \
    cd /tmp && \
    rm -rf ddb50.vsix && \
    git clone https://github.com/cs50/phpliteadmin.vsix.git && \
    cd phpliteadmin.vsix && \
    npm install && \
    vsce package && \
    mv phpliteadmin-0.0.1.vsix /opt/cs50/extensions && \
    cd /tmp && \
    rm -rf phpliteadmin.vsix && \
    git clone https://github.com/cs50/style50.vsix.git && \
    cd style50.vsix && \
    npm install && \
    vsce package && \
    mv style50-0.0.1.vsix /opt/cs50/extensions && \
    cd /tmp && \
    rm -rf style50.vsix && \
    npm uninstall -g vsce yarn


# Final stage
FROM cs50/cli:amd64
ARG DEBIAN_FRONTEND=noninteractive


# Unset user
USER root


# Copy files from builder
COPY --from=builder /build /build
COPY --from=builder /etc /etc
COPY --from=builder /opt /opt
COPY --from=builder /usr /usr
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
        gdebi-core `# For openbox (and python3, which gets pulled in)` \
        jq \
        manpages-dev \
        mysql-client \
        openbox \
        pgloader \
        php-cli \
        php-mbstring \
        php-sqlite3 \
        postgresql \
        xvfb \
        x11vnc && \
    apt clean


# Install Python packages
RUN pip3 install --no-cache-dir \
        black \
        clang-format \
        cli50 \
        djhtml \
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
