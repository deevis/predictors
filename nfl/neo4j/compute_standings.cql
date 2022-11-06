// Run PageRank algorithm prior to running this!

match(t:Team)
with collect(t) as teams
unwind teams as team
match(team)-[:DEFEATED]-(opp:Team)
optional match (team)<-[_point:EARNED_POINT]-(:Team) 
optional match (team)-[_win:DEFEATED]->(:Team) 
optional match (team)<-[_loss:DEFEATED]-(:Team)
optional match (team)-[_ties:TIED]->(:Team)
optional match (team)-[_trainwrecks:CRUSHED_BY]->(:Team)
optional match (team)<-[_crushes:CRUSHED_BY]-(:Team)
with team.label as team, team.pagerank as pagerank, 
    size(collect(distinct(_point))) as points,
    size(collect(distinct(_crushes))) as crushes,
    size(collect(distinct(_trainwrecks))) as trainwrecks,
	size(collect(distinct(_win))) as wins, 
    size(collect(distinct(_loss))) as losses,
    size(collect(distinct(_ties))) as ties,
	[n in collect(distinct(_win)) | n.win_score - n.lose_score] as winning_margins,
	[n in collect(distinct(_loss)) | n.lose_score - n.win_score] as losing_margins,
    avg(opp.pagerank) as opp_pagerank
where (wins + losses + ties) > 1
with team, pagerank, opp_pagerank, 
round(1000 * toFloat((points + crushes - (2 * trainwrecks))/toFloat(wins+losses)))/1000 as vp_avg,
points, wins, losses, ties, crushes, trainwrecks, (winning_margins + losing_margins) as margins
match (t:Team{label: team})
set t += { power_rating: ((1 + pagerank) * (1 + opp_pagerank) * vp_avg),
				opp_pagerank: opp_pagerank,
                vp_avg: vp_avg, points: points, 
                wins: wins, losses: losses, ties: ties, 
                crushes: crushes, trainwrecks: trainwrecks, margins: margins
        }
return team, 
round(1000 * (1 + pagerank) * (1 + opp_pagerank) * vp_avg)/1000 as power_rating, 
round( 1000 * pagerank)/1000 as pagerank,  round(1000 * opp_pagerank)/1000 as opp_pagerank, 
vp_avg, 
points, wins, losses, ties, crushes, trainwrecks, margins
order by power_rating DESC


