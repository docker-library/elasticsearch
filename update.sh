#!/bin/bash
set -e

SED=${SED:-sed}
cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( */ )
versions=( "${versions[@]%/}" )
downloadable=$(curl -sSL 'https://www.elastic.co/downloads/past-releases' | "$SED" -rn 's!.*?/downloads/past-releases/(elasticsearch-)?[0-9]+-[0-9]+-[0-9]+">Elasticsearch ([0-9]+\.[0-9]+\.[0-9]+)<.*!\2!gp')

for version in "${versions[@]}"; do
	recent=$(echo "$downloadable" | grep -m 1 "$version")
	"$SED" 's/%%VERSION%%/'"$recent"'/' <Dockerfile.template >"$version/Dockerfile"
	cp -p docker-entrypoint.sh $version
done
