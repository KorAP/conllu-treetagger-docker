.PHONY: clean build-docker

build-docker:
	scripts/build.sh

clean:
	docker images --quiet --filter=reference="korap/conllu-treetagger:*" | xargs -r docker rmi --force

