#!/usr/bin/env bash

# Load this file into the current shell with:
#   source ./docker-env.sh

unset DOCKER_HOST

echo "Docker shell environment activated."
echo "DOCKER_HOST has been unset; Docker will use its default socket."
