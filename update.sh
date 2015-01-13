#!/bin/bash
set -e

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

#Grab the current version from their wonderful website.
current=$(curl -sSL 'http://www.elasticsearch.org/download' | grep -o 'elasticsearch.*"version".*[0-9]\.[0-9]\.[0-9]' | grep -o '[0-9]\.[0-9]\.[0-9]')

#Replace version ENV line in Dockerfile with the current version.
sed -ri -e 's/^(ENV ELASTICSEARCH_VERSION) .*/\1 '"$current"'/' "Dockerfile"

#Download the new default configuration from the official site.
curl "https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-${current}.tar.gz" | tar zxv
mv "elasticsearch-$current/config" "config"
rm -rf "elasticsearch-$current"
