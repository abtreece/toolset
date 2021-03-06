FROM quay.io/pycontribs/python:3.8-slim-buster
# Image above is just a mirror of ^ docker.io/python:3.8-slim-buster which we
# mirror in order to avoid docker pull limiting us.
# see https://pythonspeed.com/articles/base-image-python-docker-images/
LABEL maintainer="Ansible <info@ansible.com>"

ENV PACKAGES="\
bash \
curl \
docker.io \
git \
gcc \
gnupg \
rsync \
libyaml-dev \
"

ENV PIP_INSTALL_ARGS="--pre"
ENV PYTHONDONTWRITEBYTECODE=1
ENV ANSIBLE_FORCE_COLOR=1

# podman is missing from debian 10 but will be included in 11, so for the
# moment we install it from kubic repors.
RUN \
apt-get update && \
apt-get install -y ${PACKAGES} && \
# workaround for https://github.com/containers/podman/issues/8665
echo 'deb http://deb.debian.org/debian buster-backports main' > /etc/apt/sources.list.d/backports.list && \
echo 'deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/Debian_10/ /' > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list && \
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/Debian_10/Release.key | apt-key add - && \
apt-get update && \
apt-get -t buster-backports install -y libseccomp-dev && \
apt-get install -y podman && \
apt-get clean && \
rm -rf /var/lib/apt/lists/* && \
python3 -m pip install -U --user 'pip>=20.3.1'

COPY requirements.txt /tmp/requirements.txt

RUN \
python3 -m pip install \
${PIP_INSTALL_ARGS} -r /tmp/requirements.txt && \
rm -rf /root/.cache && \
molecule --version && \
molecule drivers && \
python3 -m pip check && \
which docker && \
podman --version
# running cli commands adds a minimal level fail-safe protection
# against a broken image.
# We cannot run `docker --version` because it requires a server running and
# we do not have one, being up to the image user to mount a socket or to
# define a remote DOCKER_HOST to use.

ENV SHELL /bin/bash
