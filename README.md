# *TreeTagger* Docker Image with CoNLL-U Support

[![CI](https://github.com/KorAP/conllu-treetagger-docker/actions/workflows/ci.yml/badge.svg)](https://github.com/KorAP/conllu-treetagger-docker/actions/workflows/ci.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/korap/conllu-treetagger.svg)](https://hub.docker.com/r/korap/conllu-treetagger)
[![Docker Stars](https://img.shields.io/docker/stars/korap/conllu-treetagger.svg)](https://hub.docker.com/r/korap/conllu-treetagger)
[![GitHub issues](https://img.shields.io/github/issues/KorAP/conllu-treetagger-docker.svg)](https://github.com/KorAP/conllu-treetagger-docker/issues)
[![GitHub closed issues](https://img.shields.io/github/issues-closed/KorAP/conllu-treetagger-docker.svg)](https://github.com/KorAP/conllu-treetagger-docker/issues?q=is%3Aissue+is%3Aclosed)
[![GitHub last commit](https://img.shields.io/github/last-commit/KorAP/conllu-treetagger-docker.svg)](https://github.com/KorAP/conllu-treetagger-docker/commits/master)
[![License](https://img.shields.io/badge/License-See%20TreeTagger-blue.svg)](https://www.cis.uni-muenchen.de/~schmid/tools/TreeTagger/Tagger-Licence)

Docker image for **Helmut Schmid**'s [TreeTagger](http://www.cis.uni-muenchen.de/~schmid/tools/TreeTagger/) (based on [Stefan Fischer](https://github.com/sfischer13)'s [docker-treetagger](https://github.com/sfischer13/docker-treetagger)) with support for input and output in [CoNLL-U format](https://universaldependencies.org/format.html).

## Credits

Based on [Stefan Fischer](https://github.com/sfischer13)'s [docker-treetagger](https://github.com/sfischer13/docker-treetagger).

**Please read *Helmut Schmid*'s [license terms](https://www.cis.uni-muenchen.de/~schmid/tools/TreeTagger/Tagger-Licence) before using this Dockerfile.**

## Installation

### From [Docker Hub](https://hub.docker.com/r/korap/conllu-treetagger).

```shell
docker pull korap/conllu-treetagger
```

### From source

``` shell
git clone https://github.com/KorAP/conllu-treetagger-docker.git
cd conllu-treetagger-docker
make build-docker
```

## Usage

### Running


``` shell
$ docker run --rm -i korap/conllu-treetagger < goe.conllu | head -8

# foundry = tree_tagger
# filename = GOE/AGA/00000/base/tokens.xml
# text_id = GOE_AGA.00000
# start_offsets = 0 0 9 12
# end_offsets = 22 8 11 22
1	Campagne	<unknown>	_	NN	_	_	_	_	_
2	in	in	_	APPR	_	_	_	_	_
3	Frankreich	Frankreich	_	NE	_	_	_	_	_
```

To output different pos/lemma interpretations with their probabilities, use the `-p` option. You can optionally specify a threshold with `-t` (default: 0.1):

``` shell
$ docker run --rm -i korap/conllu-treetagger -p -t 0.01 < goe.conllu | head -8

# foundry = tree_tagger
# filename = GOE/AGA/00000/base/tokens.xml
# text_id = GOE_AGA.00000
# start_offsets = 0 0 9 12
# end_offsets = 22 8 11 22
1       Campagne        <unknown>       _       NN      _       _       _       _       _
2       in      in      _       APPR    _       _       _       _       _
3       Frankreich      Frankreich      _       NE|NN|ADJD      _       _       _       _       0.956|0.032|0.012

```
### Running with korapxmltool

`korapxmltool`, which includes `korapxml2conllu` as a shortcut, can be downloaded from [https://github.com/KorAP/korapxmltool](https://github.com/KorAP/korapxmltool).

``` shell
korapxml2conllu goe.zip | docker run --rm -i korap/conllu-treetagger -l german -p
```

#### Generate a tree-tagged KorAP XML zip directly

``` shell
korapxmltool -A "docker run --rm -i korap/conllu-treetagger" -t zip t24.zip
```

### Persisting Models

To avoid downloading the language model on every run, you can mount a local directory to `/local/models`:

``` shell
korapxml2conllu goe.zip | docker run --rm -i -v /path/to/local/models:/local/models korap/conllu-treetagger -l german
```


### Miscellaneous commands

For an overview of the available languages / models, run one of the following command:

``` shell
docker run --rm -i korap/conllu-treetagger -L
```

Open a shell within the container:

``` shell
docker run --rm -it --entrypoint /bin/bash korap/conllu-treetagger
```

## Supported languages

The language can be specified with the `-l` option. Parameter files will be downloaded automatically from the tagger's website.

The following languages are available: *Bulgarian, Catalan, Czech, Danish, Dutch, English, Estonian, Finnish, French, Galician, German, Middle High german, Greek, Ancient Greek, Ancient Greek (beta encoding), Italian, Korean, Latin, Norwegian (Bokmål), Polish, Portuguese, Portuguese (fine-grained tagset), Portuguese (alternative corpus), Romanian, Russian, Slovak, Slovenian, Spanish, Spanish (Ancora corpus), Swahili, Swedish*.
