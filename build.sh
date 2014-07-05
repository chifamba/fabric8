#!/usr/bin/env bash

echo "building the Docker container for http://fabric8.io/"
docker build -t chifamba:fabric8.base .
