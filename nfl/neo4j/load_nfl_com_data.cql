with range(1,__week_number__) as week_numbers
unwind week_numbers as week_number
with week_number, 
"file://///var/lib/neo4j/import/nfl_com_results_2022_week_week_number.json" as base_url 
with replace(base_url, "week_number", toString(week_number)) as url 
CALL apoc.load.json(url) YIELD value
unwind value.games as game
with game.id as game_id, game.date as day, game.time as time, 
      
      game.homeTeam.nickName as home_team, 
      game.homeTeam.abbreviation as home_slug, 
      game.homeTeam.currentLogo as home_logo,
      game.detail.homePointsTotal as home_score, 
      
      game.awayTeam.nickName as away_team, 
      game.awayTeam.abbreviation as away_slug,
      game.awayTeam.currentLogo as away_logo,
      game.detail.visitorPointsTotal as away_score
where game.detail.quarter = 'END_OF_GAME'
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