# Where gdb finds glibc's sources when stepping into libc (e.g., puts, malloc). Ubuntu's libc6-dbg records paths
# relative to the glibc source tree, such as ./libio/ioputs.c, so a source directory suffices (no path substitution).
# The tree is installed by the Dockerfile and extracted by /opt/cs50/bin/postCreateCommand.
directory /usr/src/glibc
