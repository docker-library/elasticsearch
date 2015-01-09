FROM java:latest

ENV ELASTICSEARCH_VERSION 1.4.2

#RUN curl https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-$ELASTICSEARCH_VERSION.tar.gz | tar xz -C /usr/local \
#	&& find /usr/local/elasticsearch-$ELASTICSEARCH_VERSION/bin -executable -type f | xargs -i ln -s "{}" "/usr/local/bin/"

RUN apt-key adv --keyserver pgp.mit.edu --recv-keys 46095ACC8548582C1A2699A9D27D666CD88E42B4
RUN echo "deb http://packages.elasticsearch.org/elasticsearch/${ELASTICSEARCH_VERSION%.*}/debian stable main" > /etc/apt/sources.list.d/elasticsearch.list

RUN apt-get update
RUN apt-get install elasticsearch
RUN find /usr/share/elasticsearch/bin -executable -type f | xargs -i ln -s "{}" "/usr/local/bin/"

CMD ["elasticsearch"]

