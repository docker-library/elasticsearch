#!/bin/bash

set -e

# Add elasticsearch as command if needed
if [ "${1:0:1}" = '-' ]; then
	set -- elasticsearch "$@"
fi

RUN_AS=${RUN_AS:-elasticsearch:elasticsearch}
RUN_AS_USER=${RUN_AS/:*/}

# Drop root privileges if we are running elasticsearch and RUN_AS is not root
if [ "$1" = 'elasticsearch' -a  "$RUN_AS_USER" != '0' -a "$RUN_AS_USER" != 'root' ]; then
	# Change the ownership of /usr/share/elasticsearch/data to elasticsearch
	chown -R $RUN_AS /usr/share/elasticsearch/data
	exec gosu $RUN_AS "$@"
fi

# As argument is not related to elasticsearch,
# then assume that user wants to run his own process,
# for example a `bash` shell to explore this image
exec "$@"
