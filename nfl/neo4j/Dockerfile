FROM  neo4j:4.4

# ENV NEO4J_AUTH=neo4j/letmein
# ARG PREDICTION_SEASON 

# ENV APOC_VERSION 4.3.0.4
# ENV APOC_URI https://github.com/neo4j-contrib/neo4j-apoc-procedures/releases/download/${APOC_VERSION}/apoc-${APOC_VERSION}-all.jar
# RUN wget -P /var/lib/neo4j/plugins ${APOC_URI}

# # https://neo4j-contrib.github.io/neo4j-graph-algorithms/versions.json
# ENV GDS_VERSION 2.2.2
# ENV GDS_URI https://graphdatascience.ninja/neo4j-graph-data-science-${GDS_VERSION}.zip
# RUN wget -P /var/lib/neo4j/plugins ${GDS_URI}

# ENV GRAPHQL_VERSION 3.4.0.1
# ENV GRAPHQL_URI https://github.com/neo4j-graphql/neo4j-graphql/releases/download/${GRAPHQL_VERSION}/neo4j-graphql-${GRAPHQL_VERSION}.jar
# RUN wget -P /var/lib/neo4j/plugins ${GRAPHQL_URI}

RUN echo "LOAD DATA FOR PREDICTIONS"
COPY ../data/ /var/lib/neo4j/import/

