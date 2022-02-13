#!/bin/bash

cd $(dirname $0)/..
[ -n "$2" ] && export target="-- set *.target=$2"
docker buildx bake -f ./tests/build.hcl --progress plain --push $1
