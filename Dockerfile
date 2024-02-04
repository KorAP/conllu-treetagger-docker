# temporary image
FROM ubuntu:latest AS treetagger_builder

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
RUN sed -i -e 's/OPTIONS="/OPTIONS="-quiet /' -e 's/^$TOKENIZER.*/cat |/' /local/cmd/tree-tagger-*

# final image
FROM alpine:latest AS treetagger

# install packages
RUN apk add --no-cache --update \
bash \
perl \
shadow \
&& rm -rf /var/cache/apk/*

# copy tagger from previous stage
COPY --from=treetagger_builder /local/ /local/

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
