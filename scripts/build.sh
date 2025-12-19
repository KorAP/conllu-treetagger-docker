#!/usr/bin/env bash

if [ $# -eq 0 ]; then
	VERSION=3.2.5
elif [ $# -eq 1 ]; then
	VERSION="$1"
else
	echo "Wrong number of arguments!"
	exit 1
fi
LOCAL_VERSION=6

docker build \
--no-cache \
--pull \
--rm \
--target treetagger \
--tag korap/conllu-treetagger:latest \
--tag korap/conllu-treetagger:"$VERSION-$LOCAL_VERSION" \
--build-arg VERSION="$VERSION" \
.

docker image prune --force
