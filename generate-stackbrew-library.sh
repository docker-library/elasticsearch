#!/bin/bash
set -e

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

#version="$(grep -m1 'ENV ELASTICSEARCH_VERSION' "Dockerfile" | cut -d' ' -f3)"
versions=( */ )
versions=( "${versions[@]%/}" )
url='git://github.com/docker-library/elasticsearch'

echo '# maintainer: InfoSiftr <github@infosiftr.com> (@infosiftr)'

for version in "${versions[@]}"; do
	commit="$(git log -1 --format='format:%H' -- $version)"
	echo "$version: ${url}@${commit} $version"
done
echo "latest: ${url}@${commit} $version"
