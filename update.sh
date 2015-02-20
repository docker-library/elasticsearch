#!/bin/bash
set -e

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( */ )
versions=( "${versions[@]%/}" )
downloadable=$(curl -sSL 'http://www.elasticsearch.org/downloads' | sed -rn 's/.*?http:\/\/www.elasticsearch.org\/downloads\/.-.-.\/\">Download v ([0-9]*\.[0-9]*\.[0-9]*)<.*/\1/gp')

for version in "${versions[@]}"; do
	recent=$(echo "$downloadable" | grep -m 1 "$version")
	sed -ri -e 's/^(ENV ELASTICSEARCH_VERSION) .*/\1 '"$recent"'/' "$version/Dockerfile"
done
