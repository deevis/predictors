docker-compose down
docker image rm nfl_neo4j



set PREDICTION_SEASON=2022
:: cd ruby

:: ruby nfl_com_scraper.rb %PREDICTION_SEASON% 
:: echo "Got result week: %errorlevel%"
:: set PREDICTION_WEEKS=%errorlevel%

:: echo "Got %PREDICTION_WEEKS% weeks of data"
:: cd ..
:: Move data into neo4j context so it can get deployed with the container 
del neo4j\data\* 
:: mkdir neo4j\data
copy .\data\nfl\%PREDICTION_SEASON%\* neo4j\data

::
:: move to separate project
::
copy .\data\premier_league\%PREDICTION_SEASON%\* neo4j\data
::
::
::

:: export PREDICTION_SEASON 
:: export PREDICTION_WEEKS

docker-compose up 
::--build-arg PREDICTION_SEASON=$PREDICTION_SEASON --build-arg PREDICTION_WEEKS=$PREDICTION_WEEKS

:: load_nfl_com_data.cql
:: run_pagerank.cql
:: compute_standings.cql
