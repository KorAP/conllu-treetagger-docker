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
RUN wget -q $DATA/ancient-greek-beta.par.gz
RUN wget -q $DATA/ancient-greek.par.gz
RUN wget -q $DATA/bulgarian.par.gz
RUN wget -q $DATA/catalan.par.gz
RUN wget -q $DATA/czech.par.gz
RUN wget -q $DATA/danish.par.gz
RUN wget -q $DATA/dutch.par.gz
RUN wget -q $DATA/english.par.gz
RUN wget -q $DATA/estonian.par.gz
RUN wget -q $DATA/finnish.par.gz
RUN wget -q $DATA/french.par.gz
RUN wget -q $DATA/galician.par.gz
RUN wget -q $DATA/german.par.gz
RUN wget -q $DATA/greek.par.gz
RUN wget -q $DATA/italian.par.gz
RUN wget -q $DATA/korean.par.gz
RUN wget -q $DATA/latin.par.gz
RUN wget -q $DATA/middle-high-german.par.gz
RUN wget -q $DATA/norwegian.par.gz
RUN wget -q $DATA/polish.par.gz
RUN wget -q $DATA/portuguese.par.gz
RUN wget -q $DATA/portuguese-finegrained.par.gz
RUN wget -q $DATA/portuguese2.par.gz
RUN wget -q $DATA/romanian.par.gz
RUN wget -q $DATA/russian.par.gz
RUN wget -q $DATA/slovak.par.gz
RUN wget -q $DATA/slovenian.par.gz
RUN wget -q $DATA/spanish.par.gz
RUN wget -q $DATA/spanish-ancora.par.gz
RUN wget -q $DATA/swahili.par.gz
RUN wget -q $DATA/swedish.par.gz

# download chunker parameter files
RUN wget -q $DATA/english-chunker.par.gz
RUN wget -q $DATA/french-chunker.par.gz
RUN wget -q $DATA/german-chunker.par.gz
RUN wget -q $DATA/spanish-chunker.par.gz

# install tagger and parameter files
RUN sh install-tagger.sh

# delete downloaded files
RUN rm install-tagger.sh *.gz

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
CMD ["--help"]

# default working directory
WORKDIR /local/

# default user
USER docker
