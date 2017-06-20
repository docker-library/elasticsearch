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
done

travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml
