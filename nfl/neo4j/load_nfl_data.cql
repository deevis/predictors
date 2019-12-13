with range(1,19) as week_numbers
unwind week_numbers as week_number
with week_number, 
case when week_number > 17 then "http://www.nfl.com/ajax/scorestrip?season=2018&seasonType=POST&week=week_number" 
else "http://www.nfl.com/ajax/scorestrip?season=2018&seasonType=REG&week=week_number" end as base_url 
with replace(base_url, "week_number", toString(week_number)) as url 
CALL apoc.load.xmlSimple(url) YIELD value
with value["_gms"]["_g"] as games
unwind games as game
with game.gsis as game_id, game.d as day, game.t as time, game.eid as entity_id, game.hnn as home_team, game.vnn as away_team, toInteger(game.hs) as home_score, toInteger(game.vs) as away_score, game.h as home_slug, game.v as away_slug,
replace('https://static.nfl.com/static/content/public/static/wildcat/assets/img/logos/teams/slug.svg', 'slug', game.h) as home_logo,
replace('https://static.nfl.com/static/content/public/static/wildcat/assets/img/logos/teams/slug.svg', 'slug', game.v) as away_logo
where home_score >= 0
merge(hTeam:Team{label: home_team, slug: home_slug, logo: home_logo})
merge(aTeam:Team{label: away_team, slug: away_slug, logo: away_logo})
  FOREACH (_ IN case when home_score > away_score then [1] else [] end|
    merge (hTeam)-[:DEFEATED { win_score: home_score, lose_score: away_score }]->(aTeam)
        create (hTeam)<-[:EARNED_POINT]-(aTeam)
        create (hTeam)<-[:EARNED_POINT]-(aTeam)
  )
  FOREACH (_ IN case when home_score < away_score then [1] else [] end|
    merge (aTeam)-[:DEFEATED { win_score: away_score, lose_score: home_score }]->(hTeam)
        create (aTeam)<-[:EARNED_POINT]-(hTeam)
        create (aTeam)<-[:EARNED_POINT]-(hTeam)
  )
  FOREACH (_ IN case when home_score >= 0 and home_score = away_score then [1] else [] end|
    merge (aTeam)-[:TIED { away_score: away_score, home_score: home_score }]->(hTeam)
    merge (aTeam)<-[:TIED { away_score: away_score, home_score: home_score }]-(hTeam)
        create (hTeam)<-[:EARNED_POINT]-(aTeam)
        create (hTeam)-[:EARNED_POINT]->(aTeam)
  )

  // Reward CRUSHED_BY points for when victory 
  FOREACH (_ IN case when home_score > ( away_score + 13) then [1] else [] end|
        create (aTeam)-[:CRUSHED_BY]->(hTeam)  
  )
  FOREACH (_ IN case when away_score > ( home_score + 13) then [1] else [] end|
        create (hTeam)-[:CRUSHED_BY]->(aTeam)  
  )

  // Reward a second CRUSHED_BY point for when victory is by 24 points
  FOREACH (_ IN case when home_score > ( away_score + 27) then [1] else [] end|
        create (aTeam)-[:CRUSHED_BY]->(hTeam)  
  )
  FOREACH (_ IN case when away_score > ( home_score + 27) then [1] else [] end|
        create (hTeam)-[:CRUSHED_BY]->(aTeam)  
  )