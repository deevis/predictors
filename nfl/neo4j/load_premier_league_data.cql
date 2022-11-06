with range(0,__total_pages__) as pages
unwind pages as page
with page, 
"file://///var/lib/neo4j/import/results_2022_page_page_number.json" as base_url 
with replace(base_url, "page_number", toString(page)) as url 
CALL apoc.load.json(url) YIELD value

with value.game_id as game_id, value.date as day, value.week as week,
      
      value.home_team as home_team, 
      value.home_score as home_score, 
      
      value.away_team as away_team, 
      value.away_score as away_score

where value.status = 'C'
merge(hTeam:Team{label: home_team})
merge(aTeam:Team{label: away_team})
  FOREACH (_ IN case when home_score > away_score then [1] else [] end|
    merge (hTeam)-[:DEFEATED { win_score: home_score, lose_score: away_score }]->(aTeam)
        create (hTeam)<-[:EARNED_POINT]-(aTeam)
        create (hTeam)<-[:EARNED_POINT]-(aTeam)
        create (hTeam)<-[:EARNED_POINT]-(aTeam)
  )
  FOREACH (_ IN case when home_score < away_score then [1] else [] end|
    merge (aTeam)-[:DEFEATED { win_score: away_score, lose_score: home_score }]->(hTeam)
        create (aTeam)<-[:EARNED_POINT]-(hTeam)
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
  FOREACH (_ IN case when home_score > ( away_score + 3) then [1] else [] end|
        create (aTeam)-[:CRUSHED_BY]->(hTeam)  
  )
  FOREACH (_ IN case when away_score > ( home_score + 3) then [1] else [] end|
        create (hTeam)-[:CRUSHED_BY]->(aTeam)  
  )

  // Reward a second CRUSHED_BY point for when victory is by 24 points
  FOREACH (_ IN case when home_score > ( away_score + 6) then [1] else [] end|
        create (aTeam)-[:CRUSHED_BY]->(hTeam)  
  )
  FOREACH (_ IN case when away_score > ( home_score + 6) then [1] else [] end|
        create (hTeam)-[:CRUSHED_BY]->(aTeam)  
  )