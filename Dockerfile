# Build stage
FROM cs50/cli:amd64-minimized as builder
ARG DEBIAN_FRONTEND=noninteractive


# Unset user
USER root


# Install glibc sources for debugger
# https://github.com/Microsoft/vscode-cpptools/issues/1123#issuecomment-335867997
RUN echo "deb-src http://archive.ubuntu.com/ubuntu/ jammy main restricted" > /etc/apt/sources.list.d/_.list && \
    apt update && \
    apt install --no-install-recommends --yes dpkg-dev && \
    cd /tmp && \
    apt source glibc && \
    rm -rf *.tar.* *.dsc && \
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


# Install VS Code extensions
RUN npm install -g vsce yarn && \
    mkdir --parents /opt/cs50/extensions && \
    cd /tmp && \
    git clone https://github.com/cs50/ai50.vsix.git && \
    cd ai50.vsix && \
    npm install && \
    vsce package && \
    mv ai50-1.0.0.vsix /opt/cs50/extensions && \
    cd /tmp && \
    rm -rf ai50.vsix && \
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
FROM cs50/cli:amd64-minimized
ARG DEBIAN_FRONTEND=noninteractive


# Unset user
USER root


# Copy files from builder
COPY --from=builder /build/glibc-sMfBJT /build/glibc-sMfBJT
COPY --from=builder /usr/local/bin/lua /usr/local/bin/lua
COPY --from=builder /opt/noVNC /opt/noVNC
COPY --from=builder /opt/cs50/extensions /opt/cs50/extensions
COPY --from=builder /opt/share/bfg-1.14.0.jar /opt/share/bfg-1.14.0.jar
RUN chown -R ubuntu:ubuntu /opt/share
RUN pip3 install --no-cache-dir /opt/cs50/extensions/cs50vsix-client/ && \
    rm -rf /opt/cs50/extensions/cs50vsix-client


# set virtual display
ENV DISPLAY=":0"


# Install Ubuntu packages
# Install acl for temporarily removing ACLs via opt/cs50/bin/postCreateCommand
# https://github.community/t/bug-umask-does-not-seem-to-be-respected/129638/9
RUN apt update && apt install --no-install-recommends --yes \
        acl \
        clang-format \
        dwarfdump \
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
    cli50 \
    matplotlib \
    pytz


# Enforce login shell
RUN echo "shopt -q login_shell || bash --login" >> /home/ubuntu/.bashrc && \
    chown -R ubuntu:ubuntu /home/ubuntu/.bashrc


# Copy files to image
COPY ./etc /etc
COPY ./opt /opt
RUN chmod a+rx /opt/cs50/bin/* && \
    chmod a+rx /opt/cs50/phpliteadmin/bin/phpliteadmin && \
    ln --symbolic /opt/cs50/phpliteadmin/bin/phpliteadmin /opt/cs50/bin/phpliteadmin


# Temporary workaround for https://github.com/cs50/cs50.dev/issues/19
RUN echo "if [ -z \"\$_PROFILE_D\" ] ; then for i in /etc/profile.d/*.sh; do if ["$i" == "/etc/profile.d/debuginfod*"] ; then continue; fi; . \"\$i\"; done; export _PROFILE_D=1; fi"


# Set user
USER ubuntu
