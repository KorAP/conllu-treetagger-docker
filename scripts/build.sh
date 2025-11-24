#!/usr/bin/env bash

if [ $# -eq 0 ]; then
	VERSION=3.2.5
elif [ $# -eq 1 ]; then
	VERSION="$1"
else
	echo "Wrong number of arguments!"
	exit 1
fi
LOCAL_VERSION=4

docker build \
--no-cache \
--pull \
--rm \
--target treetagger \
--tag korap/conllu2treetagger:latest \
--tag korap/conllu2treetagger:"$VERSION-$LOCAL_VERSION" \
--build-arg VERSION="$VERSION" \
.

docker image prune --force
