#!/usr/bin/env bash
set -Eeuo pipefail

# "docker history", but ignoring/munging known problematic bits for the purposes of creating image diffs

docker image history --no-trunc --format '{{ .CreatedBy }}' "$@" \
	| tac \
	| sed -r 's!^/bin/sh[[:space:]]+-c[[:space:]]+(#[(]nop[)][[:space:]]+)?!!' \
	| gawk '
		# munge the checksum of the first ADD of the base image (base image changes unnecessarily break our diffs)
		NR == 1 && $1 == "ADD" && $4 == "/" { $2 = "-" }

		# remove "org.label-schema.build-date" and "org.opencontainers.image.created" (https://github.com/elastic/dockerfiles/pull/101#pullrequestreview-879623350)
		$1 == "LABEL" { gsub(/ (org[.]label-schema[.]build-date|org[.]opencontainers[.]image[.]created)=[^ ]+( [0-9:+-]+)?/, "") }

		# remove several buildkit-isms
		/# buildkit$/ {
			sub(/^RUN[[:space:]]+/, "")
			sub(/^\/bin\/sh[[:space:]]+-c[[:space:]]+/, "")
			sub(/[[:space:]]*# buildkit$/, "")
		}
		$1 == "EXPOSE" { gsub(/map\[|\/tcp:\{\}|\]/, "") }
		# buildkit makes COPY expressions hyper-simplified ("COPY --chown=1000:0 --from=foo /foo /bar" becomes just "COPY /foo /bar" vs "COPY --chown=1000:0 dir:xxxx in /bar")
		$1 == "COPY" { $0 = gensub(/^[[:space:]]*(COPY)[[:space:]]+([^[:space:]]+[[:space:]]+)+([^[:space:]]+)[[:space:]]*$/, "\\1 ... \\3", 1) }

		# sane and sanitized, print it!
		{ print }
	'
