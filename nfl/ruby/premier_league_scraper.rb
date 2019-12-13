curl 'https://footballapi.pulselive.com/football/fixtures?comps=1&compSeasons=210&teams=1,127,131,43,46,4,6,7,34,159,26,10,11,12,23,20,21,33,25,38&page=2&pageSize=40&sort=desc&statuses=C&altIds=true' -H 'Referer: https://www.premierleague.com/results' -H 'Origin: https://www.premierleague.com' --compressed > pl.json
json = File.read("pl.json")
data = JSON.parse(json)

require 'rest-client'
seasons = JSON.parse(RestClient.get("https://footballapi.pulselive.com/football/seasons?pageSize=100"))
year = "2019"
season = seasons["content"].detect{|s| s["label"].start_with?("Season #{year}")}
# {"label"=>"Season 2019/2020", "id"=>28.0}