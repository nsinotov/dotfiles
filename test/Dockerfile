# ===========================================
# Fresh-install test image (Ubuntu)
# ===========================================
# Simulates a new machine: only git and sudo are present (bash login shell),
# and apt package lists are empty. Everything else must come from install.sh.
#
#   docker build -f test/Dockerfile -t dotfiles-test .
#   docker run --rm dotfiles-test

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8

RUN apt-get update \
 && apt-get install -y --no-install-recommends git sudo ca-certificates curl \
 && rm -rf /var/lib/apt/lists/*

# Regular user with passwordless sudo, like a personal workstation account
RUN useradd -m -s /bin/bash tester \
 && echo 'tester ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/tester

USER tester
WORKDIR /home/tester

COPY --chown=tester:tester . /home/tester/.dotfiles

CMD ["bash", "/home/tester/.dotfiles/test/run.sh"]
