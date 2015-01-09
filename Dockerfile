FROM java:latest

ENV ELASTICSEARCH_VERSION 1.4.2

RUN apt-key adv --keyserver pgp.mit.edu --recv-keys 46095ACC8548582C1A2699A9D27D666CD88E42B4
RUN echo "deb http://packages.elasticsearch.org/elasticsearch/${ELASTICSEARCH_VERSION%.*}/debian stable main" > /etc/apt/sources.list.d/elasticsearch.list


#The real thing - disabled for quick iteration
#RUN apt-get update \
#	&& apt-get install elasticsearch \
#	&& rm -rf /var/lib/apt/lists/*

RUN apt-get update
RUN apt-get install elasticsearch
RUN find /usr/share/elasticsearch/bin -executable -type f | xargs -i ln -s "{}" "/usr/local/bin/"

EXPOSE 9200 9300

CMD ["elasticsearch"]

