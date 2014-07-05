#!/usr/bin/env bash

echo "Starting the fabric8 container"
docker run -p 8181 -p 22 -d -t chifamba:fabric8-base
