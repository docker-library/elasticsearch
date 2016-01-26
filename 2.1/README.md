# elasticsearch:2.1.1

![](https://raw.githubusercontent.com/docker-library/docs/7688e51a41c0c10dca4e6c376be886ce64b9620f/elasticsearch/logo.png)

# What is Elasticsearch?

Elasticsearch is a search server based on Lucene. It provides a distributed, multitenant-capable full-text search engine with a RESTful web interface and schema-free JSON documents.

Elasticsearch is a registered trademark of Elasticsearch BV. More info https://en.wikipedia.org/wiki/Elasticsearch.

# Docker compose

```yml
elasticsearch:
  image: elasticsearch:2.1.1
#  volumes:
#    - ./persistant_folder/data:/usr/share/elasticsearch/data
#    - ./persistant_folder/logs:/usr/share/elasticsearch/logs
#    - ./persistant_folder/plugins:/usr/share/elasticsearch/plugins
  ports:
    - "9200:9200"
    - "9300:9300"
  environment:
    - CLUSTER_NAME=myClusterName
    - NODE_NAME=Tars
  restart: always
```

Remove `#` to persiste elasticsearch data, logs and installed plugins

# Available Configuration Parameters

- **CLUSTER_NAME**: Use a descriptive name for your cluster. Defaults to `elasticsearch`
- **NODE_NAME**: Use a descriptive name for the node. Defaults to `Iron Man`
