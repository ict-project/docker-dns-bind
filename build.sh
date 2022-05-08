#!/bin/bash

CONFIG_PREFIX="$1"
CONFIG_SUFFIX="$2"
CONFIG_SUFFIX_DC="${CONFIG_PREFIX}docker-config${CONFIG_SUFFIX}"

GIT_VERSION=$(git describe 2> /dev/null || echo unknown)

if [[ ! -f "Dockerfile" ]]; then
    echo "Dockerfile is mising!!!"
    exit 1
fi

echo "Building image..."
docker image build --tag dns-bind:$GIT_VERSION .
echo "Done..."

if [[ "PREFIX$CONFIG_PREFIX" == "PREFIX" ]]; then
echo "In order to run interactively use this command:"
echo "docker run --read-only --rm -it -p 53:53/udp -p 53:53/tcp dns-bind:$GIT_VERSION"
echo
echo "In order to run in normal mode use this command:"
echo "docker run --read-only -d  -p 53:53/udp -p 53:53/tcp dns-bind:$GIT_VERSION"
echo
else
echo "In order to create config use this commands:"
echo "docker config create $CONFIG_SUFFIX_DC docker.config"
echo
CONFIGS="$CONFIGS --config source=$CONFIG_SUFFIX_DC,target=/etc/bind/docker.config,mode=0400,uid=100,gid=101"
echo "In order to run as a service use this command:"
echo "docker service create --read-only -d $CONFIGS -p 53:53/udp -p 53:53/tcp dns-bind:$GIT_VERSION"
echo
fi
echo "In order to save image use this command:"
echo "docker save -o dns-bind_$GIT_VERSION.tar dns-bind:$GIT_VERSION"
echo
echo "In order to load image use this command:"
echo "docker load -i dns-bind_$GIT_VERSION.tar"
echo
