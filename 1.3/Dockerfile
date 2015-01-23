FROM java:latest

ENV ELASTICSEARCH_VERSION 1.3.7

RUN apt-key adv --keyserver pgp.mit.edu --recv-keys 46095ACC8548582C1A2699A9D27D666CD88E42B4
RUN echo "deb http://packages.elasticsearch.org/elasticsearch/${ELASTICSEARCH_VERSION%.*}/debian stable main" > /etc/apt/sources.list.d/elasticsearch.list


RUN apt-get update \
	&& apt-get install elasticsearch=$ELASTICSEARCH_VERSION \
	&& rm -rf /var/lib/apt/lists/*

RUN find /usr/share/elasticsearch/bin -executable -type f | xargs -i ln -s "{}" "/usr/local/bin/"
COPY config /usr/share/elasticsearch/config

EXPOSE 9200 9300

CMD ["elasticsearch"]

