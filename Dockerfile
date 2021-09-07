FROM cs50/cli:minimal
ARG DEBIAN_FRONTEND=noninteractive


# Unset user
USER root


# Install Ubuntu packages
RUN apt update && \
    apt install --yes \
        jq


# Copy files to image
COPY ./etc /etc
COPY ./opt /opt
RUN chmod a+rx /opt/cs50/bin/*


# Temporarily install Python packages locally
RUN pip3 install /opt/cs50/extensions/python-clients/cs50vsix-client/


# Temporarily remove ACLs
# https://github.community/t/bug-umask-does-not-seem-to-be-respected/129638/9
RUN apt update && \
    apt install acl && \
    sudo setfacl -bnR /workspaces/*


# Temporary workaround for https://github.com/cs50/code.cs50.io/issues/19
RUN echo "if [ -z \"\$_PROFILE_D\" ] ; then for i in /etc/profile.d/*.sh; do . \"\$i\"; done; export _PROFILE_D=1; fi" >> /etc/bash.bashrc


# Set user
USER ubuntu
