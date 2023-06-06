FROM cs50/cli:amd64
ARG DEBIAN_FRONTEND=noninteractive


# Unset user
USER root


# Install glibc sources for debugger
# https://github.com/Microsoft/vscode-cpptools/issues/1123#issuecomment-335867997
RUN echo "deb-src http://archive.ubuntu.com/ubuntu/ focal main restricted" > /etc/apt/sources.list.d/_.list && \
    apt update && \
    cd /tmp && \
    apt source glibc && \
    rm -f /etc/apt/sources.list.d/_.list && \
    apt update && \
    mkdir --parents /build/glibc-sMfBJT && \
    mv glibc* /build/glibc-sMfBJT && \
    cd /build/glibc-sMfBJT \
    rm -rf *.tar.xz *.dsc && \
    rm -rf /var/lib/apt/lists/*


# Install window manager, X server, x11vnc (VNC server), noVNC (VNC client)
ENV DISPLAY=":0"
RUN apt update && apt install --no-install-recommends --yes \
    openbox \
    xvfb \
    x11vnc

RUN wget https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.zip -P/tmp && \
    unzip /tmp/v1.4.0.zip -d /tmp && \
    mv /tmp/noVNC-1.4.0 /opt/noVNC && \
    rm -rf /tmp/noVNC-1.4.0 /tmp/v1.4.0.zip && \
    chown -R ubuntu:ubuntu /opt/noVNC


# Install Ubuntu packages
RUN apt update && \
    apt install --no-install-recommends --yes \
        clang-format \
        dwarfdump \
        jq \
        manpages-dev \
        mysql-client \
        pgloader \
        php-cli \
        php-mbstring \
        php-sqlite3 \
        postgresql && \
        rm -rf /var/lib/apt/lists/*


# For temporarily removing ACLs via opt/cs50/bin/postCreateCommand
# https://github.community/t/bug-umask-does-not-seem-to-be-respected/129638/9
RUN apt update && \
    apt install --no-install-recommends --yes acl && \
    rm -rf /var/lib/apt/lists/*


# Install Python packages
RUN pip3 install --no-cache-dir \
    black \
    cli50


# Install BFG
RUN wget https://repo1.maven.org/maven2/com/madgag/bfg/1.14.0/bfg-1.14.0.jar -P /opt/share && \
    chown -R ubuntu:ubuntu /opt/share


# Install Lua 5.x
RUN wget http://www.lua.org/ftp/lua-5.4.4.tar.gz -P/tmp && \
    cd /tmp && \
    tar zxf lua-5.4.4.tar.gz && \
    cd lua-5.4.4 && \
    make all install && \
    cd /tmp && \
    rm -rf /tmp/lua-5.4.4*


# Enforce login shell
RUN echo "shopt -q login_shell || bash --login" >> /home/ubuntu/.bashrc && \
    chown -R ubuntu:ubuntu /home/ubuntu/.bashrc


# Invalidate caching for the remaining instructions
ARG VCS_REF


# Install VS Code extensions
RUN npm install -g vsce yarn && \
    mkdir --parents /opt/cs50/extensions && \
    cd /tmp && \
    git clone https://github.com/cs50/cs50.vsix.git && \
    cd cs50.vsix && \
    npm install && \
    vsce package && \
    mv cs50-0.0.1.vsix /opt/cs50/extensions && \
    pip3 install --no-cache-dir python-clients/cs50vsix-client/ && \
    cd /tmp && \
    rm -rf cs50.vsix && \
    git clone https://github.com/cs50/ai50.vsix.git && \
    cd ai50.vsix && \
    npm install && \
    vsce package && \
    mv ai50-1.0.0.vsix /opt/cs50/extensions && \
    cd /tmp && \
    rm -rf ai50.vsix && \
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


# Copy files to image
COPY ./etc /etc
COPY ./opt /opt
RUN chmod a+rx /opt/cs50/bin/*
RUN chmod a+rx /opt/cs50/phpliteadmin/bin/phpliteadmin
RUN ln --symbolic /opt/cs50/phpliteadmin/bin/phpliteadmin /opt/cs50/bin/phpliteadmin


# Temporary workaround for https://github.com/cs50/cs50.dev/issues/19
RUN echo "if [ -z \"\$_PROFILE_D\" ] ; then for i in /etc/profile.d/*.sh; do if ["$i" == "/etc/profile.d/debuginfod*"] ; then continue; fi; . \"\$i\"; done; export _PROFILE_D=1; fi"


# Temporary fix for https://github.com/microsoft/vscode-cpptools/issues/103#issuecomment-1151217772
RUN wget https://launchpad.net/ubuntu/+source/gdb/12.1-0ubuntu1/+build/23606376/+files/gdb_12.1-0ubuntu1_amd64.deb -P/tmp && \
    apt install /tmp/gdb_12.1-0ubuntu1_amd64.deb && \
    rm -rf /tmp/gdb_12.1-0ubuntu1_amd64.deb


# Set user
USER ubuntu
