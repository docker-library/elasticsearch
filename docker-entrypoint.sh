#!/bin/bash

set -e

# Add elasticsearch as command if needed
if [ "${1:0:1}" = '-' ]; then
	set -- elasticsearch "$@"
fi

# Drop root privileges if we are running elasticsearch
if [ "$1" = 'elasticsearch' ]; then
    # Change ownership of directories holding
    # persisted data (indices and logs)
    # so that elasticsearch can modify their content
    for dir in data logs ; do
        [ -d "/usr/share/elasticsearch/$dir" ] && \
        chown -R elasticsearch:elasticsearch "/usr/share/elasticsearch/$dir"
    done
	exec gosu elasticsearch "$@"
fi

# As argument is not related to elasticsearch,
# then assume that user wants to run his own process,
# for example a `bash` shell to explore this image
exec "$@"
