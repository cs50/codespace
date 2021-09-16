FROM cs50/cli:minimal
ARG DEBIAN_FRONTEND=noninteractive


# Unset user
USER root


# Install Ubuntu packages
RUN apt update && \
    apt install --yes \
        jq


# Install submit50@classroom
RUN pip3 install git+https://github.com/cs50/submit50@classroom


# Copy files to image
COPY ./etc /etc
COPY ./opt /opt
COPY ./autograde.sh /
RUN chmod a+rx /autograde.sh
RUN chmod a+rx /opt/cs50/bin/*


# Load glibc-2.31 library for debugger
RUN mkdir -p /build/glibc-eX1tMB
RUN tar -xf /opt/cs50/glibc-2.31.tar.xz -C /build/glibc-eX1tMB
RUN chmod a+rx /build/glibc-eX1tMB
RUN rm -f /opt/cs50/glibc-2.31.tar.xz


# Temporarily install Python packages locally
RUN pip3 install /opt/cs50/extensions/python-clients/cs50vsix-client/


# For temporarily removing ACLs via opt/cs50/bin/postCreateCommand
# https://github.community/t/bug-umask-does-not-seem-to-be-respected/129638/9
RUN apt update && \
    apt install acl


# Temporary workaround for https://github.com/cs50/code.cs50.io/issues/19
RUN echo "if [ -z \"\$_PROFILE_D\" ] ; then for i in /etc/profile.d/*.sh; do . \"\$i\"; done; export _PROFILE_D=1; fi" >> /etc/bash.bashrc


# Set user
USER ubuntu
