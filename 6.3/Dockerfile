# this Dockerfile was created from Dockerfile-oss (which was generated from upstream's build system)

FROM centos:7

ENV ELASTIC_CONTAINER true

RUN curl -s https://download.java.net/java/GA/jdk10/10.0.2/19aef61b38124481863b1413dce1855f/13/openjdk-10.0.2_linux-x64_bin.tar.gz | tar -C /opt -zxf -
ENV JAVA_HOME /opt/jdk-10.0.2

# Replace OpenJDK's built-in CA certificate keystore with the one from the OS
# vendor. The latter is superior in several ways.
# REF: https://github.com/elastic/elasticsearch-docker/issues/171
RUN ln -sf /etc/pki/ca-trust/extracted/java/cacerts /opt/jdk-10.0.2/lib/security/cacerts

RUN yum update -y && \
    yum install -y nc unzip wget which && \
    yum clean all

RUN groupadd -g 1000 elasticsearch && \
    adduser -u 1000 -g 1000 -G 0 -d /usr/share/elasticsearch elasticsearch && \
    chmod 0775 /usr/share/elasticsearch && \
    chgrp 0 /usr/share/elasticsearch

WORKDIR /usr/share/elasticsearch
ENV PATH /usr/share/elasticsearch/bin:$PATH
USER 1000
RUN set -ex; \
    curl -fsSL https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-oss-6.3.2.tar.gz | \
    tar zx --strip-components=1; \
    for esdirs in config data logs; do \
        mkdir -p "$esdirs"; \
    done; \
    for PLUGIN in ingest-user-agent ingest-geoip; do \
        elasticsearch-plugin install --batch "$PLUGIN"; \
    done; \
    chown -R elasticsearch:0 .; \
    chmod -R g=u .; \
# clean up some extra zero-byte bits left behind in /tmp
    rm -rvf /tmp/*elasticsearch*
USER 0
COPY --chown=1000:0 elasticsearch.yml log4j2.properties config/

COPY --chown=1000:0 bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# Openshift overrides USER and uses ones with randomly uid>1024 and gid=0
# Allow ENTRYPOINT (and ES) to run even with a different user
RUN chgrp 0 /usr/local/bin/docker-entrypoint.sh && \
    chmod g=u /etc/passwd && \
    chmod 0775 /usr/local/bin/docker-entrypoint.sh

EXPOSE 9200 9300

LABEL org.label-schema.schema-version="1.0" \
  org.label-schema.vendor="Elastic" \
  org.label-schema.name="elasticsearch" \
  org.label-schema.version="6.3.2" \
  org.label-schema.url="https://www.elastic.co/products/elasticsearch" \
  org.label-schema.vcs-url="https://github.com/elastic/elasticsearch-docker" \
license="Apache-2.0"
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
# Dummy overridable parameter parsed by entrypoint
CMD ["eswrapper"]
