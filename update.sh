#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */ )
fi
versions=( "${versions[@]%/}" )

tags="$(
	git ls-remote --tags https://github.com/elastic/dockerfiles.git \
		| cut -d/ -f3 \
		| grep -E '^v' \
		| cut -d^ -f1 \
		| sort -uV
)"

travisEnv=
for version in "${versions[@]}"; do
	rcVersion="${version%-rc}"
	rcGrepV='-v'
	if [ "$version" != "$rcVersion" ]; then
		rcGrepV=
	fi

	fullVersion="$(
		grep -P "^\Qv$rcVersion." <<<"$tags" \
			| grep $rcGrepV -E -- '-(alpha|beta|rc)' \
			| tail -1
	)"
	if [ -z "$fullVersion" ]; then
		echo >&2 "warning: cannot find full version for $version"
		continue
	fi
	fullVersion="${fullVersion#v}"

	echo "$version: $fullVersion"

	upstreamImage="docker.elastic.co/elasticsearch/elasticsearch:$fullVersion"

	# Parse image manifest for sha
	authToken="$(curl -fsSL 'https://docker-auth.elastic.co/auth?service=token-service&scope=repository:elasticsearch/elasticsearch:pull' | jq -r .token)"
	digest="$(curl --head -fsSL -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' -H "Authorization: Bearer $authToken" "https://docker.elastic.co/v2/elasticsearch/elasticsearch/manifests/$fullVersion" | tr -d '\r' | gawk -F ':[[:space:]]+' '$1 == "Docker-Content-Digest" { print $2 }')"

	# Format image reference (image@sha)
	upstreamImageDigest="$upstreamImage@$digest"

	upstreamDockerfileLink="https://github.com/elastic/dockerfiles/tree/v$fullVersion/elasticsearch"
	upstreamDockerfile="${upstreamDockerfileLink//tree/raw}/Dockerfile"

	(
		set -x
		curl -fsSL -o /dev/null "$upstreamDockerfileLink" # make sure the upstream Dockerfile link exists
		curl -fsSL "$upstreamDockerfile" | grep -P "\Q$fullVersion" # ... and that it contains the right version
	)

	sed -e 's!%%ELASTICSEARCH_VERSION%%!'"$fullVersion"'!g' \
		-e 's!%%UPSTREAM_IMAGE_DIGEST%%!'"$upstreamImageDigest"'!g' \
		-e 's!%%UPSTREAM_DOCKERFILE_LINK%%!'"$upstreamDockerfileLink"'!g' \
		Dockerfile.template > "$version/Dockerfile"

	travisEnv='\n  - VERSION='"$version VARIANT=$travisEnv"
done

travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
cat <<<"$travis" > .travis.yml
