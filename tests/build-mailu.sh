#!/bin/bash

#[ -n "$1" ] && export target="-- set *.target=$1"
docker buildx bake -f tests/build.hcl --progress plain --push $1
