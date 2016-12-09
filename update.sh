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
	debRepo=
	if [ "$majorVersion" -ge 5 ]; then
		debRepo="https://artifacts.elastic.co/packages/$aptBucket/apt"
	elif [ "$majorVersion" -ge 2 ]; then
		debRepo="http://packages.elasticsearch.org/elasticsearch/$aptBucket/debian"
	else
		debRepo="http://packages.elasticsearch.org/elasticsearch/$rcVersion/debian"
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
		(
			set -x
			cp docker-entrypoint.sh "$version/alpine/"
			sed -i 's/gosu/su-exec/g' "$version/alpine/docker-entrypoint.sh"
			sed \
				-e 's!%%ELASTICSEARCH_VERSION%%!'"$plainVersion"'!g' \
				Dockerfile-alpine.template > "$version/alpine/Dockerfile"
		)
		travisEnv='\n  - VERSION='"$version VARIANT=alpine$travisEnv"
	fi
	travisEnv='\n  - VERSION='"$version VARIANT=$travisEnv"
done

travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml
