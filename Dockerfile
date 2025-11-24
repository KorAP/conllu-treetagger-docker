# temporary image
FROM ubuntu:22.04 AS treetagger_builder

# TreeTagger version
ARG VERSION=3.2.5

# metadata
LABEL maintainer="Marc Kupietz <kupietz@ids-mannheim.de>"

# apt-get settings
ARG DEBIAN_FRONTEND=noninteractive

# install packages
RUN apt-get update \
&& apt-get install -y --no-install-recommends \
ca-certificates \
publicsuffix \
wget \
&& apt-get autoremove -y \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/*

# tagger location
RUN mkdir /local/
WORKDIR /local/

# tagger URL
ARG DATA=https://www.cis.uni-muenchen.de/~schmid/tools/TreeTagger/data

# download tagger files
RUN wget -q $DATA/tree-tagger-linux-$VERSION.tar.gz
RUN wget -q $DATA/tagger-scripts.tar.gz
RUN wget -q $DATA/install-tagger.sh

# download parameter files
RUN wget -q $DATA/english.par.gz
RUN wget -q $DATA/german.par.gz

# install tagger and parameter files
RUN sh install-tagger.sh

# delete downloaded files
RUN rm *.gz

# skip tokenization and be quiet
# RUN sed -i -e 's/OPTIONS="/OPTIONS="-quiet -proto-with-prob /' -e 's/^$TOKENIZER.*/cat |/' /local/cmd/tree-tagger-*
RUN sed -i -e 's/OPTIONS="/OPTIONS="-quiet /' -e 's/^$TOKENIZER.*/cat |/' -e 's/$TAGGER $OPTIONS $PARFILE/$TAGGER $OPTIONS $PARFILE $*/' /local/cmd/tree-tagger-*

# replace awk/sed with perl
# COPY scripts/filter-german-tags.pl /local/cmd/filter-german-tags
RUN ln -s /local/bin/korap-treetagger-processor /local/cmd/filter-german-tags
RUN ln -s /local/bin/korap-treetagger-processor /local/cmd/filter-german-tags

# rust builder
FROM rust:1.79-alpine3.20 AS rust_builder
WORKDIR /usr/src/app
RUN apk add --no-cache musl-dev
COPY korap-treetagger-processor .
RUN cargo build --release

# final image
FROM alpine:3.19 AS treetagger

# install packages
RUN apk add --no-cache --update \
gawk \
bash \
perl \
shadow \
&& rm -rf /var/cache/apk/*

# copy tagger from previous stage
COPY --from=treetagger_builder /local/ /local/
COPY --from=rust_builder /usr/src/app/target/release/korap-treetagger-processor /local/bin/korap-treetagger-processor

# set path
ENV PATH /local/bin:/local/cmd:$PATH

# add non-root user
RUN groupadd docker \
&& useradd -g docker docker

# change owner
RUN chown -R docker:docker /local/

# make sure binaries are executable
RUN chmod a+x /local/bin/*

# default command
COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]

# default working directory
WORKDIR /local/

# default user
USER docker
