#!/bin/bash
set -e

declare -A aliases
aliases=(
	[1.6]='1 latest'
)

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( */ )
versions=( "${versions[@]%/}" )
url='git://github.com/docker-library/elasticsearch'

echo '# maintainer: InfoSiftr <github@infosiftr.com> (@infosiftr)'

for version in "${versions[@]}"; do
	commit="$(git log -1 --format='format:%H' -- "$version")"
	fullVersion="$(grep -m1 'ENV ELASTICSEARCH_VERSION' "$version/Dockerfile" | cut -d' ' -f3)"
	
	versionAliases=()
	while [ "$fullVersion" != "$version" -a "${fullVersion%[.-]*}" != "$fullVersion" ]; do
		versionAliases+=( $fullVersion )
		fullVersion="${fullVersion%[.-]*}"
	done
	versionAliases+=( $version ${aliases[$version]} )
	
	echo
	for va in "${versionAliases[@]}"; do
		echo "$va: ${url}@${commit} $version"
	done
done
