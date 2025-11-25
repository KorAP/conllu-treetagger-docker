# *TreeTagger* Docker Image with CoNLL-U Support

[![Docker Build Status](https://img.shields.io/docker/cloud/build/korap/conllu-treetagger.svg)](https://hub.docker.com/r/korap/conllu-treetagger)
[![Docker Pulls](https://img.shields.io/docker/pulls/korap/conllu-treetagger.svg)](https://hub.docker.com/r/korap/conllu-treetagger)
[![Docker Stars](https://img.shields.io/docker/stars/korap/conllu-treetagger.svg)](https://hub.docker.com/r/korap/conllu-treetagger)
[![Docker Automated build](https://img.shields.io/docker/cloud/automated/korap/conllu-treetagger.svg)](https://hub.docker.com/r/korap/conllu-treetagger)

Docker image for **Helmut Schmid**'s [TreeTagger](http://www.cis.uni-muenchen.de/~schmid/tools/TreeTagger/) (based on [Stefan Fischer](https://github.com/sfischer13)'s [docker-treetagger](https://github.com/sfischer13/docker-treetagger)) with support for input and output in [CoNLL-U format](https://universaldependencies.org/format.html).

## Credits

Based on [Stefan Fischer](https://github.com/sfischer13)'s [docker-treetagger](https://github.com/sfischer13/docker-treetagger).

**Please read *Helmut Schmid*'s [license terms](https://www.cis.uni-muenchen.de/~schmid/tools/TreeTagger/Tagger-Licence) before using this Dockerfile.**

## Summary

This image includes some recent parameter files available on the tagger's website.

Texts in the following languages can be **tagged**: *Bulgarian, Catalan, Czech, Danish, Dutch, English, Estonian, Finnish, French, Galician, German, Middle High german, Greek, Ancient Greek, Ancient Greek (beta encoding), Italian, Korean, Latin, Norwegian (Bokmål), Polish, Portuguese, Portuguese (fine-grained tagset), Portuguese (alternative corpus), Romanian, Russian, Slovak, Slovenian, Spanish, Spanish (Ancora corpus), Swahili, Swedish*.

## Installation

### Install docker image (from [internal gitlab artifacts](https://gitlab.ids-mannheim.de/KorAP/conllu-treetagger-docker/-/jobs/artifacts/master/browse?job=build-docker-image))

```shell
curl -Ls 'https://gitlab.ids-mannheim.de/KorAP/conllu-treetagger-docker/-/jobs/artifacts/master/raw/conllu-treetagger.xz?job=build-docker-image' | docker load
```

### Build from source

In order to build the image, you have to clone the repository.

Then, build the Docker image.

``` shell
make build-docker
```

## Usage

### Running

Note: `korapxml2conllu` (used in the running examples) can be downloaded from [https://github.com/KorAP/korapxmltool](https://github.com/KorAP/korapxmltool).

``` shell
korapxml2conllu goe.zip | docker run --rm -i korap/conllu-treetagger -l german
```

To output probabilities, use the `-p` option:

``` shell
korapxml2conllu goe.zip | docker run --rm -i korap/conllu-treetagger -l german -p
```

#### Persisting Models

To avoid downloading the language model on every run, you can mount a local directory to `/local/models`:

``` shell
korapxml2conllu goe.zip | docker run --rm -i -v /path/to/local/models:/local/models korap/conllu-treetagger -l german
```

#### Miscellaneous commands

For an overview of the available languages / models, run one of the following command:

``` shell
docker run --rm -i korap/conllu-treetagger -L
```

Open a shell within the container:

``` shell
docker run --rm -it --entrypoint /bin/bash korap/conllu-treetagger
```
