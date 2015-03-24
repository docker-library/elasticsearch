#!/bin/bash
set -e

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( */ )
versions=( "${versions[@]%/}" )
downloadable=$(curl -sSL 'https://www.elastic.co/downloads/past-releases' | sed -rn 's!.*?/downloads/past-releases/(elasticsearch-)?[0-9]+-[0-9]+-[0-9]+">Elasticsearch ([0-9]+\.[0-9]+\.[0-9]+)<.*!\2!gp')

for version in "${versions[@]}"; do
	recent=$(echo "$downloadable" | grep -m 1 "$version")
	sed 's/%%VERSION%%/'"$recent"'/' <Dockerfile.template >"$version/Dockerfile"
	cp -p docker-entrypoint.sh $version
done
