FROM docker.elastic.co/elasticsearch/elasticsearch:5.1.1

ENV plugin_install  "bin/elasticsearch-plugin install --verbose --batch"
 
RUN $plugin_install analysis-icu
#RUN $plugin_install repository-gcs

