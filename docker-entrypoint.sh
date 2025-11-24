#!/bin/bash

set -o pipefail

# Default values
lang="german"

usage() {
    echo "Usage: $0 [-h] [-l LANG] [-L]"
    echo "  -h            Display this help message"
    echo "  -l LANG       Specify a language (default: $lang)"
    echo "  -L            List available languages/models"
    exit 1
}

# Parse command line options
while getopts "hl:Lp" opt; do
    case $opt in
        h)
            usage
            ;;
        l)
            lang="$OPTARG"
            ;;
        L)
            ls /local/cmd/tree-tagger-* | sed -e 's/.*tree-tagger-//'
            exit 0
            ;;
        p)
            PROB="-proto-with-prob"
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument" >&2
            usage
            ;;
    esac
done

if [ $OPTIND -le $# ]; then
    usage
fi

if ! compgen -G  "/local/lib/${lang}*.par" > /dev/null; then
    wget https://www.cis.uni-muenchen.de/~schmid/tools/TreeTagger/data/${lang}.par.gz >&2 # -O /local/lib/${lang}.par.gz
    bash install-tagger.sh > /dev/null
    if ! compgen -G  "/local/lib/${lang}*.par" > /dev/null; then
        echo "ERROR: Could not install model for language $lang, aborting." >&2;
        exit 1
    fi
fi

perl -wlnpe'$_=substr($_, 0, 99000); s/^(#.*|$)/<$1>/; s/^[\d.]+\t([^\t]*).*/$1/' |  tree-tagger-$lang $PROB | \
 perl -wlne 's/^<(.*)>$/$1/; s/^(# *foundry *= *)base/$1 tree_tagger/; $id++; $id=0 if(/^(#|\s*$)/); my @cols = split("\t"); if(@cols == 3) { print "$id\t$cols[0]\t$cols[2]\t_\t$cols[1]\t_\t_\t_\t_\t_"} elsif (@cols > 3) { my $extra = join(" ", @cols[3..$#cols]); $extra =~ s/^[fsc]\s+//; my @tags; my @probs; my @probs_cols = split(/\s+/, $extra); for (my $i=0; $i < @probs_cols; $i+=2) { push @tags, $probs_cols[$i]; push @probs, $probs_cols[$i+1]; }; my $xpos = join("|", @tags); my $misc = (scalar(@tags) == 1) ? "_" : join("|", @probs); print "$id\t$cols[0]\t$cols[2]\t_\t$xpos\t_\t_\t_\t_\t$misc" } else {print $_;}'

