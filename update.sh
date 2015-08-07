#!/bin/bash
set -e

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( */ )
versions=( "${versions[@]%/}" )
downloadable=$({
	# get a few pages worth so we make sure to capture a decent number of releases
	curl -fsSL 'https://www.elastic.co/downloads/past-releases'
	curl -fsSL 'https://www.elastic.co/downloads/past-releases?page=2'
	curl -fsSL 'https://www.elastic.co/downloads/past-releases?page=3'
} | sed -rn 's!.*?/downloads/past-releases/(elasticsearch-)?[0-9]+-[0-9]+-[0-9]+">Elasticsearch ([0-9]+\.[0-9]+\.[0-9]+)<.*!\2!gp')

travisEnv=
for version in "${versions[@]}"; do
	travisEnv='\n  - VERSION='"$version$travisEnv"
	
	recent=$(echo "$downloadable" | grep -m 1 "^$version" || true)
	if [ -z "$recent" ]; then
		echo >&2 "warning: cannot find full version for $version"
		continue
	fi
	sed 's/%%VERSION%%/'"$recent"'/' <Dockerfile.template >"$version/Dockerfile"
	cp -p docker-entrypoint.sh $version
done

travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml
