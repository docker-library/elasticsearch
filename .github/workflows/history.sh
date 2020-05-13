#!/usr/bin/env bash
set -Eeuo pipefail

# "docker history", but ignoring/munging known problematic bits for the purposes of creating image diffs

docker image history --no-trunc --format '{{ .CreatedBy }}' "$@" \
	| tac \
	| sed -r 's!^/bin/sh[[:space:]]+-c[[:space:]]+(#[(]nop[)][[:space:]]+)?!!' \
	| awk '
		# ignore the first ADD of the base image (base image changes unnecessarily break our diffs)
		NR == 1 && $1 == "ADD" && $4 == "/" { next }
		# TODO consider instead just removing the checksum in $3

		# ignore obviously "centos" LABEL instructions (include a timestamp, so base image changes unnecessarily break our diffs)
		$1 == "LABEL" && / org.opencontainers.image.vendor=CentOS | org.label-schema.vendor=CentOS / { next }

		# just ignore the default CentOS CMD value (not relevant to our needs)
		$0 == "CMD [\"/bin/bash\"]" { next }

		# ignore the contents of certain copies (notoriously unreliable hashes because they often contain timestamps)
		$1 == "COPY" && ($4 == "/usr/share/elasticsearch" || $4 ~ /^\/opt\/jdk-/) { gsub(/:[0-9a-f]{64}$/, ":filtered-content-hash", $2) }

		# sane and sanitized, print it!
		{ print }
	'
