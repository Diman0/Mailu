#!/bin/bash
set -xe
# first time only
#git remote -v
#git remote add upstream https://github.com/Mailu/Mailu.git
git fetch upstream
git checkout master
git merge upstream/master
read -p 'ok for pushing?' ok
case "$ok" in
  "y"|"Y"|"o"|"O") git push;;
  *) echo "not pushing";;
esac

