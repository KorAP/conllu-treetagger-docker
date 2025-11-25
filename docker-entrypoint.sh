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

MODEL_DIR="/local/models"
PAR_FILE="${lang}.par"
PAR_GZ="${lang}.par.gz"
URL="https://www.cis.uni-muenchen.de/~schmid/tools/TreeTagger/data/${PAR_GZ}"

# Ensure MODEL_DIR exists
mkdir -p "$MODEL_DIR"

# Function to install model
install_model() {
    local src="$1"
    local dest="/local/lib/$PAR_FILE"
    
    if [ -f "$dest" ]; then
        return 0
    fi

    if [[ "$src" == *.gz ]]; then
        gzip -cd "$src" > "$dest"
    else
        ln -sf "$src" "$dest"
    fi
}

# Check if model exists in MODEL_DIR (uncompressed)
if [ -f "$MODEL_DIR/$PAR_FILE" ]; then
    echo "Using existing model from $MODEL_DIR/$PAR_FILE" >&2
    install_model "$MODEL_DIR/$PAR_FILE"

# Check if model exists in MODEL_DIR (compressed)
elif [ -f "$MODEL_DIR/$PAR_GZ" ]; then
    echo "Using existing compressed model from $MODEL_DIR/$PAR_GZ" >&2
    # Try to unzip to MODEL_DIR to cache it
    if [ -w "$MODEL_DIR" ] && gzip -cd "$MODEL_DIR/$PAR_GZ" > "$MODEL_DIR/$PAR_FILE" 2>/dev/null; then
        echo "Cached uncompressed model to $MODEL_DIR/$PAR_FILE" >&2
        install_model "$MODEL_DIR/$PAR_FILE"
    else
        echo "Cannot write to $MODEL_DIR, unzipping to /local/lib only" >&2
        install_model "$MODEL_DIR/$PAR_GZ"
    fi

# Download if not found
else
    echo "Downloading $lang model..." >&2
    # Try to download to MODEL_DIR
    if [ -w "$MODEL_DIR" ] && wget -q "$URL" -O "$MODEL_DIR/$PAR_GZ" 2>/dev/null; then
        echo "Saved model to $MODEL_DIR/$PAR_GZ" >&2
        # Try to unzip to MODEL_DIR
        if gzip -cd "$MODEL_DIR/$PAR_GZ" > "$MODEL_DIR/$PAR_FILE" 2>/dev/null; then
             install_model "$MODEL_DIR/$PAR_FILE"
        else
             install_model "$MODEL_DIR/$PAR_GZ"
        fi
    else
        echo "Cannot write to $MODEL_DIR, downloading to /local/lib (ephemeral)" >&2
        wget -q "$URL" -O "/local/lib/$PAR_GZ"
        install_model "/local/lib/$PAR_GZ"
        rm "/local/lib/$PAR_GZ"
    fi
fi

if [ ! -f "/local/lib/$PAR_FILE" ]; then
    echo "ERROR: Could not install model for language $lang, aborting." >&2;
    exit 1
fi

korap-treetagger-processor preprocess |  tree-tagger-$lang $PROB | \
 korap-treetagger-processor postprocess

