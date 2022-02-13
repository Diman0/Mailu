#!/bin/bash

set -e

IMAGES="docs setup admin rainloop roundcube fetchmail traefik-certdumper rspamd nginx dovecot postfix clamav unbound radicale"
REGISTRY_NAME="https://index.docker.io"
TAG_OLD=1.9-multiarch-latest
CONTENT_TYPE="application/vnd.docker.distribution.manifest.v2+json"
AUTH="https://auth.docker.io"
SERV="registry.docker.io"

function usage() {
  echo $0 -t new_tag [-i "image list"]
  exit 1
}

while getopts ":ht:i:" flag
do
	case "${flag}" in
		h) usage;;
		t) TAG_NEW="${OPTARG}";;
		i) IMAGES="${OPTARG}";;
		*) usage;;
	esac
done

[ -z "$TAG_NEW" ] && usage

read -p "Will add the tag '$TAG_NEW' to mailu images [$IMAGES] tagged '$TAG_OLD'. OK? (y/N)" ok
[ "$ok" != "y" ] && exit 2

# set username and password
read -p "docker hub login: " UNAME
read -sp "docker hub personal access token: " UPAT
echo

function update_repo() {
  IMAGE=$1
  REPO="${UNAME}/${IMAGE}"
# get token to be able to talk to Docker Hub
  AUTH_SCOPE=scope=repository:${REPO}:pull,push
  TOKEN=$(curl -u ${UNAME}:${UPAT} -s -L "${AUTH}/token?service=${SERV}&${AUTH_SCOPE}" | jq --raw-output .token) # && echo ${TOKEN}

  MANIFEST_URL=${REGISTRY_NAME}/v2/${REPO}/manifests
  MANIFEST=$(curl -s -L -H "Authorization:Bearer ${TOKEN}" -H "Accept: ${CONTENT_TYPE}" "${MANIFEST_URL}/${TAG_OLD}" | jq --raw-output) 

  curl -X PUT -H "Authorization:Bearer ${TOKEN}" -H "Content-Type: ${CONTENT_TYPE}" -d "${MANIFEST}" "${MANIFEST_URL}/${TAG_NEW}" \
    && echo "Repo ${REPO} updated with tag ${TAG_NEW}"
}


for i in $IMAGES;
do update_repo "mailu-$i"
done

