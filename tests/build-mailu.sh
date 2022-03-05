#!/bin/bash

function usage() {
  echo $0 '[-h] [-p platform(s)] [-i "image list"] [-n] [-l]'
  echo "-p comma separated list of platforms. default=linux/amd64,linux/arm64,linux/arm/v7"
  echo "-i images to be built. default=all"
  echo "-n no cache"
  echo "-l load only, don't push to docker registry"
  echo "-h prints this help and exits"
  exit 1
}

IMAGES=""
PLATFORMS=""
NOCACHE=""
LOAD="--push"

while getopts ":hp:i:nl" flag
do
  case "${flag}" in
    h) usage;;
    p) PLATFORMS='--set *.platform='"${OPTARG}";;
    i) IMAGES="${OPTARG}";;
    n) NOCACHE="--no-cache";;
    l) LOAD="--load";;
    *) usage;;
  esac
done

cd $(dirname $0)/..
docker run --privileged --rm tonistiigi/binfmt --install all
set -x
docker buildx bake -f ./tests/build.hcl --progress plain $NOCACHE $LOAD $PLATFORMS $IMAGES
