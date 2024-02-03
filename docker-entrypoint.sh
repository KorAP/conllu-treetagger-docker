#!/usr/bin/env bash

set -e -o pipefail

if [ "$1" = '--help' ]; then
    exec ls -1 /local/bin /local/cmd
fi

sed -e 's/^\(#.*\|$\)/<\1>/ ' -e 's/\t.*//' |  exec "$@" | \
 perl -wlne 's/^<(.*)>$/$1/; s/^(# *foundry *= *)base/$1 tt/; $id++; $id=0 if(/^(#|\s*$)/); my @cols = split("\t"); if(@cols > 2) { print "$id\t$cols[0]\t$cols[2]\t$cols[1]\t$cols[1]\t_\t_\t_\t_\t_"} else {print $_;}'

