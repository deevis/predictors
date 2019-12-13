with range(1,14) as week_numbers
unwind week_numbers as week_number
with replace("file:////var/lib/neo4j/import/ncaa_results_2018_week_week_number.json", "week_number", toString(week_number)) as url 
CALL apoc.load.json(url) YIELD value
unwind value.result as game
with game[0].team as away_team_name, game[0].team_id as away_slug, 
        game[0].logo as away_logo, toInteger(game[0].points) as away_score,
     game[1].team as home_team_name, game[1].team_id as home_slug, 
        game[1].logo as home_logo, toInteger(game[1].points) as home_score
where home_score >= 0
merge(hTeam:Team{slug: home_slug})
on create set hTeam += {label: home_team_name, logo: home_logo}
merge(aTeam:Team{slug: away_slug})
on create set aTeam += {label: away_team_name, logo: away_logo}
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
