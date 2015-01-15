#!/bin/bash
set -e

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"
echo '# maintainer: InfoSiftr <github@infosiftr.com> (@infosiftr)'

url='git://github.com/docker-library/elasticsearch'
version="$(grep -m1 'ENV ELASTICSEARCH_VERSION' "Dockerfile" | cut -d' ' -f3)"
commit="$(git log -1 --format='format:%H' -- .)"
echo "$version: ${url}@${commit} $version"
echo "latest: ${url}@${commit} $version"
