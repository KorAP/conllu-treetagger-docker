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

korap-treetagger-processor preprocess |  tree-tagger-$lang $PROB | \
 korap-treetagger-processor postprocess

