#!/bin/bash
set -e

if [[  $(uname) == "Darwin" ]]; then
	SED=gsed
	RL_OPTS=""
else
	SED=sed
	RL_OPTS="-f"
fi

cd "$(dirname "$(readlink ${RL_OPTS} "$BASH_SOURCE")")"

versions=( */ )
versions=( "${versions[@]%/}" )
downloadable=$(curl -sSL 'https://www.elastic.co/downloads/past-releases' | ${SED} -rn 's!.*?/downloads/past-releases/[0-9]+-[0-9]+-[0-9]+">Elasticsearch ([0-9]+\.[0-9]+\.[0-9]+)<.*!\1!gp')

for version in "${versions[@]}"; do
	recent=$(echo "$downloadable" | grep -m 1 "$version")
	sed 's/%%VERSION%%/'"$recent"'/' <Dockerfile.template >"$version/Dockerfile"
	cp -p docker-entrypoint.sh $version
done
