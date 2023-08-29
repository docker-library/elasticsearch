#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */ )
fi
versions=( "${versions[@]%/}" )

upstreamProduct='elasticsearch'

upstreamDockerfileRepo='https://github.com/elastic/dockerfiles'

tags="$(
	git ls-remote --tags "$upstreamDockerfileRepo.git" \
		| cut -d/ -f3 \
		| grep -E '^v' \
		| cut -d^ -f1 \
		| sort -uV
)"

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

	upstreamImageRepo="$upstreamProduct/$upstreamProduct"
	upstreamImage="docker.elastic.co/$upstreamImageRepo:$fullVersion"

	# Parse image manifest for sha
	authToken="$(curl -fsSL "https://docker-auth.elastic.co/auth?service=token-service&scope=repository:$upstreamImageRepo:pull" | jq -r .token)"
	manifestList="$(
		curl -D- -fsSL \
			-H 'Accept: application/vnd.docker.distribution.manifest.list.v2+json' \
			-H 'Accept: application/vnd.docker.distribution.manifest.v2+json' \
			-H "Authorization: Bearer $authToken" \
			"https://docker.elastic.co/v2/$upstreamImageRepo/manifests/$fullVersion" \
			| tr -d '\r'
	)"
	digest="$(gawk -F ':[[:space:]]+' 'tolower($1) == "docker-content-digest" { print $2; exit }' <<<"$manifestList")"
	manifestList="$(gawk '/^$/ { pre = 1; next } pre { print }' <<<"$manifestList")"

	# Format image reference (image@sha)
	upstreamImageDigest="$upstreamImage@$digest"

	schemaVersion="$(jq -r '.schemaVersion' <<<"$manifestList")"
	[ "$schemaVersion" = 2 ] # sanity check
	mediaType="$(jq -r '.mediaType' <<<"$manifestList")"
	case "$mediaType" in
		'application/vnd.docker.distribution.manifest.v2+json')
			upstreamImageArchitectures='amd64'
			;;

		'application/vnd.docker.distribution.manifest.list.v2+json')
			upstreamImageArchitectures="$(
				jq -r '
					.manifests[].platform
					| if .os != "linux" then
						.os + "-"
					else "" end
					+ if .architecture == "arm" then
						"arm32"
					elif .architecture == "386" then
						"i386"
					else .architecture end
					+ if .variant then
						.variant
					elif .architecture == "arm64" then
						"v8"
					else "" end
				' <<<"$manifestList" \
				| sort -u \
				| xargs
			)"
			;;

		*)
			echo >&2 "error: unknown media type on '$upstreamImageDigest': '$mediaType'"
			exit 1
			;;
	esac

	upstreamDockerfileTag="v$fullVersion"
	upstreamDockerfileLink="https://github.com/elastic/dockerfiles/tree/$upstreamDockerfileTag/$upstreamProduct"
	upstreamDockerfile="${upstreamDockerfileLink//tree/raw}/Dockerfile"

	(
		set -x
		curl -fsSL -o /dev/null "$upstreamDockerfileLink" # make sure the upstream Dockerfile link exists
		curl -fsSL "$upstreamDockerfile" | grep -P "\Q$fullVersion" # ... and that it contains the right version
	)

	upstreamDockerBuild="$upstreamDockerfileRepo.git#$upstreamDockerfileTag:$upstreamProduct"

	sed -e 's!%%VERSION%%!'"$fullVersion"'!g' \
		-e 's!%%UPSTREAM_IMAGE_DIGEST%%!'"$upstreamImageDigest"'!g' \
		-e 's!%%UPSTREAM_IMAGE_ARCHITECTURES%%!'"$upstreamImageArchitectures"'!g' \
		-e 's!%%UPSTREAM_DOCKERFILE_LINK%%!'"$upstreamDockerfileLink"'!g' \
		-e 's!%%UPSTREAM_DOCKER_BUILD%%!'"$upstreamDockerBuild"'!g' \
		Dockerfile.template > "$version/Dockerfile"
done
