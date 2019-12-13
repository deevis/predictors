with ["2019-03-01","2019-03-02","2019-03-03"] as dates
unwind dates as date
with date, replace("file:////var/lib/neo4j/import/ncaa/basketball_results__date_.json", "_date_", date) as url 
CALL apoc.load.json(url) YIELD value
unwind value.result as game
with date, game[0].team as away_team_name, game[0].team_id as away_slug, 
        game[0].logo as away_logo, toInteger(game[0].points) as away_score,
     game[1].team as home_team_name, game[1].team_id as home_slug, 
        game[1].logo as home_logo, toInteger(game[1].points) as home_score
where home_score >= 0
merge(hTeam:Team{slug: home_slug})
on create set hTeam += {label: home_team_name, logo: home_logo}
merge(aTeam:Team{slug: away_slug})
on create set aTeam += {label: away_team_name, logo: away_logo}
  FOREACH (_ IN case when home_score > away_score then [1] else [] end|
    merge (hTeam)-[:DEFEATED { date: date, win_score: home_score, lose_score: away_score }]->(aTeam)
        create (hTeam)<-[:EARNED_POINT{ date: date}]-(aTeam)
      //   create (hTeam)<-[:EARNED_POINT{ date: date}]-(aTeam)
      //   create (hTeam)<-[:EARNED_POINT{ date: date}]-(aTeam)
  )
  FOREACH (_ IN case when home_score < away_score then [1] else [] end|
    merge (aTeam)-[:DEFEATED { date: date, win_score: away_score, lose_score: home_score }]->(hTeam)
        create (aTeam)<-[:EARNED_POINT{ date: date}]-(hTeam)
      //   create (aTeam)<-[:EARNED_POINT{ date: date}]-(hTeam)
      //   create (aTeam)<-[:EARNED_POINT{ date: date}]-(hTeam)
  )
//   FOREACH (_ IN case when home_score >= 0 and home_score = away_score then [1] else [] end|
//     merge (aTeam)-[:TIED { date: date, away_score: away_score, home_score: home_score }]->(hTeam)
//     merge (aTeam)<-[:TIED { date: date, away_score: away_score, home_score: home_score }]-(hTeam)
//   )

  // Reward CRUSHED_BY points for when victory 
  FOREACH (_ IN case when home_score >= ( away_score + 15) then [1] else [] end|
        create (aTeam)-[:CRUSHED_BY{ date: date}]->(hTeam)  
  )
  FOREACH (_ IN case when away_score >= ( home_score + 15) then [1] else [] end|
        create (hTeam)-[:CRUSHED_BY{ date: date}]->(aTeam)  
  )

  // Reward a second CRUSHED_BY point for when victory is by 24 points
  FOREACH (_ IN case when home_score >= ( away_score + 30) then [1] else [] end|
        create (aTeam)-[:CRUSHED_BY]->(hTeam)  
  )
  FOREACH (_ IN case when away_score >= ( home_score + 30) then [1] else [] end|
        create (hTeam)-[:CRUSHED_BY]->(aTeam)  
  )