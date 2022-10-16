#!/bin/bash
docker-compose down
docker image rm nfl_neo4j

PREDICTION_SEASON=2022
cd ruby
ruby nfl_com_scraper.rb $PREDICTION_SEASON 
PREDICTION_WEEKS=$?
echo -e "Got $PREDICTION_WEEKS weeks of data"
cd ..
# Move data into neo4j context so it can get deployed with the container 
rm -fr neo4j/data 
mkdir -p neo4j/data
cp ./data/nfl/${PREDICTION_SEASON}/* neo4j/data

export PREDICTION_SEASON 
export PREDICTION_WEEKS

docker-compose up 
