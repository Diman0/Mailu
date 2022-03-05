#!/bin/bash

set -e

# check jq is installed
which jq > /dev/null || (echo "$0 needs jq to be installed."; exit 2);

IMAGES="docs setup admin rainloop roundcube fetchmail traefik-certdumper rspamd nginx dovecot postfix clamav unbound radicale"
REGISTRY_NAME="https://index.docker.io"
TAG_OLD=1.9-multiarch
CONTENT_TYPE="application/vnd.docker.distribution.manifest.list.v2+json"
AUTH="https://auth.docker.io"
SERV="registry.docker.io"

function usage() {
  echo "$0 {-t new_tag | -d old-tag} [-i \"image list\"] [-n] [-h]"
  echo "re tags Mailu images"
  echo "-t new_tag add new tag to image tagged ${TAG_OLD}"
  echo "-d old_tag deletes old_tag on the images"
  echo "-i liste of images between \"\". default to all mailu images"
  echo "-n no login (ie already logged in to docker hub)"
  echo "-h prints this help and exits"
  exit 1
}

while getopts ":ht:d:i:n" flag
do
	case "${flag}" in
		h) usage;;
		t) TAG_NEW="${OPTARG}";;
    d) DEL_TAG="${OPTARG}";;
		i) IMAGES="${OPTARG}";;
    n) NOLOGIN=true;;
		*) usage;;
	esac
done

[ -z "$TAG_NEW" -a -z "$DEL_TAG" ] && usage
[ -n "$TAG_NEW" -a -n "$DEL_TAG" ] && echo "-t and -d option are mutually exclusive" && usage
prompt="Will remove the tag '$DEL_TAG' from mailu images [$IMAGES]. OK? (y/N): "
[ -n "$TAG_NEW" ] && prompt="Will add the tag '$TAG_NEW' to mailu images [$IMAGES] tagged '$TAG_OLD'. OK? (y/N): "
read -p "$prompt" ok
[ "$ok" != "y" ] && exit 2

AUTHFILE=~/.docker/.auth
if [ -z "$NOLOGIN" ]; then
# set username and password
  read -p "docker hub login: " UNAME
  read -sp "docker hub personal access token: " UPAT
  echo
  # warning, auth kept in clear
  echo "{ \"uname\":\"${UNAME}\", \"upat\":\"${UPAT}\" }" > ${AUTHFILE}
else
  UNAME=$(cat ${AUTHFILE} | jq --raw-output .uname)
  UPAT=$(cat ${AUTHFILE} | jq --raw-output .upat)
fi

function update_repo() {
  IMAGE=$1
  REPO="${UNAME}/${IMAGE}"
  if [ -n "$TAG_NEW" ]; then
    # get token to be able to talk to Docker Hub
    AUTH_SCOPE=scope=repository:${REPO}:pull,push
    TOKEN=$(curl -u ${UNAME}:${UPAT} -s -L "${AUTH}/token?service=${SERV}&${AUTH_SCOPE}" | jq --raw-output .token) #&& echo ${TOKEN}
    MANIFEST_URL=${REGISTRY_NAME}/v2/${REPO}/manifests
    # docker hub API does not return full manifest for multiarch images, use docker manifest instead
    MANIFEST=$(docker manifest inspect $REPO:$TAG_OLD)
    #  $(curl -s -L -H "Authorization:Bearer ${TOKEN}" -H "Accept: ${CONTENT_TYPE}" "${MANIFEST_URL}/${TAG_OLD}" | jq --raw-output) 
    curl -X PUT -H "Authorization:Bearer ${TOKEN}" -H "Content-Type: ${CONTENT_TYPE}" -d "${MANIFEST}" "${MANIFEST_URL}/${TAG_NEW}" \
      && echo "Repo ${REPO} updated with tag ${TAG_NEW}"
  else
    TOKEN=$(curl -s -H "Content-Type: application/json" -X POST -d "{\"username\":\"$UNAME\",\"password\":\"$UPAT\"}" \
      "https://hub.docker.com/v2/users/login/" | jq -r .token)
    curl "https://hub.docker.com/v2/repositories/${REPO}/tags/${DEL_TAG}/" \
      -X DELETE \
      -H "Authorization: JWT ${TOKEN}" \
      && echo "Tag ${DEL_TAG} removed from $REPO"
  fi
}

for i in $IMAGES;
do update_repo "mailu-$i"
done

