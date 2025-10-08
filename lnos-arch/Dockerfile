# Dockfile for LnOS Arch 
# wip build - docker build -t lnos-builder .
FROM archlinux:latest

RUN pacman -Syu --noconfirm archiso git base-devel

RUN useradd -m builder && echo "builder ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builder
USER builder
WORKDIR /work

ENTRYPOINT ["bash","-lc"]
