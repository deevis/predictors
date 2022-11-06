## predictors - nfl.com - from bash
cd ruby
ruby nfl_com_scraper.rb

# in powershell cuz no docker in wsl (so far...)
cd ../neo4j
.\build.bat

# from bash again...
cd ruby
ruby predictor_nfl.rb



## predictors - premier league - from bash
cd ruby
ruby premier_league_scraper.rb

# in powershell cuz no docker in wsl (so far...)
cd ../neo4j
.\build.bat

# from bash again...
cd ruby
ruby predictor_premier_league.rb
