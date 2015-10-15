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
	travisEnv='\n  - VERSION='"$version$travisEnv"
	
	repoBase="http://packages.elasticsearch.org/elasticsearch/$version/debian"
	if [ "${version%%.*}" -ge 2 ]; then
		repoBase="http://packages.elasticsearch.org/elasticsearch/${version%%.*}.x/debian"
	fi
	
	fullVersion="$(curl -fsSL "$repoBase/dists/stable/main/binary-amd64/Packages" | awk -F ': ' '$1 == "Package" { pkg = $2 } pkg == "elasticsearch" && $1 == "Version" { print $2 }' | sort -rV | head -n1)"
	if [ -z "$fullVersion" ]; then
		echo >&2 "warning: cannot find full version for $version"
		continue
	fi
	(
		set -x
		cp docker-entrypoint.sh Dockerfile.template "$version/"
		mv "$version/Dockerfile.template" "$version/Dockerfile"
		sed -i '
			s/%%ELASTICSEARCH_MAJOR%%/'"$version"'/g;
			s/%%ELASTICSEARCH_VERSION%%/'"$fullVersion"'/g;
			s!%%ELASTICSEARCH_REPO_BASE%%!'"$repoBase"'!g;
		' "$version/Dockerfile"
	)
done

travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml
