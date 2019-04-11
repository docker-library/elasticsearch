#!/bin/bash
set -e

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */ )
fi
versions=( "${versions[@]%/}" )

travisEnv=
for version in "${versions[@]}"; do
	rcVersion="${version%-rc}"

	majorVersion="${rcVersion%%.*}"
	aptBucket="${majorVersion}.x"
	if [ "$rcVersion" != "$version" ]; then
		aptBucket+='-prerelease'
	fi
	debRepo="https://artifacts.elastic.co/packages/$aptBucket/apt"
	tarballUrlBase='https://artifacts.elastic.co/downloads'
	if [ "$majorVersion" -eq 2 ]; then
		debRepo="http://packages.elasticsearch.org/elasticsearch/$aptBucket/debian"
		tarballUrlBase='https://download.elastic.co/elasticsearch'
	fi

	fullVersion="$(curl -fsSL "$debRepo/dists/stable/main/binary-amd64/Packages" | awk -F ': ' '$1 == "Package" { pkg = $2 } pkg == "elasticsearch" && $1 == "Version" && $2 ~ /^([0-9]+:)?'"$rcVersion"'/ { print $2 }' | sort -rV | head -n1)"
	if [ -z "$fullVersion" ]; then
		echo >&2 "warning: cannot find full version for $version"
		continue
	fi
	# convert "1:5.0.2-1" over to "5.0.2"
	plainVersion="${fullVersion%%-*}" # strip non-upstream-version
	plainVersion="${plainVersion##*:}" # strip epoch
	tilde='~'; plainVersion="${plainVersion//$tilde/-}" # replace '~' with '-'

	if [ $majorVersion -ge 6 ]; then
		# Use the "upstream" Dockerfile, which rebundles the existing image from Elastic.
		upstreamImage="docker.elastic.co/elasticsearch/elasticsearch:$plainVersion"

		# Parse image manifest for sha
		authToken="$(curl -fsSL 'https://docker-auth.elastic.co/auth?service=token-service&scope=repository:elasticsearch/elasticsearch:pull' | jq -r .token)"
		digest="$(curl --head -fsSL -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' -H "Authorization: Bearer $authToken" "https://docker.elastic.co/v2/elasticsearch/elasticsearch/manifests/$plainVersion" | tr -d '\r' | gawk -F ':[[:space:]]+' '$1 == "Docker-Content-Digest" { print $2 }')"

		# Format image reference (image@sha)
		upstreamImageDigest="$upstreamImage@$digest"

		upstreamDockerfileLink="https://github.com/elastic/dockerfiles/tree/v$plainVersion/elasticsearch"
		upstreamDockerfile="${upstreamDockerfileLink//tree/raw}/Dockerfile"

		(
			set -x
			curl -fsSL -o /dev/null "$upstreamDockerfileLink" # make sure the upstream Dockerfile link exists
			curl -fsSL "$upstreamDockerfile" | grep -P "\Q$plainVersion" # ... and that it contains the right version
			sed '
				s!%%ELASTICSEARCH_VERSION%%!'"$plainVersion"'!g;
				s!%%UPSTREAM_IMAGE_DIGEST%%!'"$upstreamImageDigest"'!g;
				s!%%UPSTREAM_DOCKERFILE_LINK%%!'"$upstreamDockerfileLink"'!g;
			' Dockerfile-upstream.template > "$version/Dockerfile"
		)
		travisEnv='\n  - VERSION='"$version VARIANT=$travisEnv"
	else
		# Use the traditional build system where we build up the image ourselves.
		(
			set -x
			cp docker-entrypoint.sh "$version/"
			sed '
				s!%%ELASTICSEARCH_VERSION%%!'"$plainVersion"'!g;
				s!%%ELASTICSEARCH_DEB_REPO%%!'"$debRepo"'!g;
				s!%%ELASTICSEARCH_DEB_VERSION%%!'"$fullVersion"'!g;
			' Dockerfile-debian.template > "$version/Dockerfile"
		)

		if [ -d "$version/alpine" ]; then
			tarball="$tarballUrlBase/elasticsearch/elasticsearch-${plainVersion}.tar.gz"
			tarballAsc="${tarball}.asc"
			if ! wget --quiet --spider "$tarballAsc"; then
				tarballAsc=
			fi
			tarballSha1=
			for sha1Url in "${tarball}.sha1" "${tarball}.sha1.txt"; do
				if sha1="$(wget -qO- "$sha1Url")"; then
					tarballSha1="${sha1%% *}"
					break
				fi
			done
			(
				set -x
				cp docker-entrypoint.sh "$version/alpine/"
				sed -i 's/gosu/su-exec/g' "$version/alpine/docker-entrypoint.sh"
				sed \
					-e 's!%%ELASTICSEARCH_VERSION%%!'"$plainVersion"'!g' \
					-e 's!%%ELASTICSEARCH_TARBALL%%!'"$tarball"'!g' \
					-e 's!%%ELASTICSEARCH_TARBALL_ASC%%!'"$tarballAsc"'!g' \
					-e 's!%%ELASTICSEARCH_TARBALL_SHA1%%!'"$tarballSha1"'!g' \
					Dockerfile-alpine.template > "$version/alpine/Dockerfile"
			)
			travisEnv='\n  - VERSION='"$version VARIANT=alpine$travisEnv"
		fi
		travisEnv='\n  - VERSION='"$version VARIANT=$travisEnv"
	fi
done

travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml
