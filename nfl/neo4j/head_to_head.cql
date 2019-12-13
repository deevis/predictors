// The graph view of the HeadToHead opponenets
match(t1:Team{label: "patriots"})
match(t2:Team{label: "chiefs"})
with t1, t2
optional match(t1)-[t1o1:DEFEATED]->(o1)-[o1t2:DEFEATED]->(t2)
optional match(t1)<-[o2t1:DEFEATED]-(o2)<-[t2o2:DEFEATED]-(t2)
with t1, t2, o1, o2, t1o1, o1t2, o2t1, t2o2 
optional match(t1)-[t1t2:DEFEATED]->(t2)
optional match(t1)<-[t2t1:DEFEATED]-(t1)
optional match(t1)<-[o1t1:DEFEATED]-(o1)
optional match(t2)<-[o2t2:DEFEATED]-(o2)
optional match(t1)-[t1o2:DEFEATED]->(o2)
optional match(t2)-[t2o1:DEFEATED]-(o1)
return distinct t1, t2, o1, o2, 
t1t2, t1o1, t1o2,
t2t1, t2o1, t2o2, 
o1t2, o1t1,  
o2t1, o2t2


// The points earned by each team from the HeadToHead opponents view
match(t1:Team {label: "Xavier"})
match(t2:Team {label: "Providence"})
optional match(t1)-[t11_wins:DEFEATED]->(:Team)-[t12_wins:DEFEATED]->(t2) 
optional match(t2)-[t21_wins:DEFEATED]->(:Team)-[t22_wins:DEFEATED]->(t1) 
optional match(t1)-[t1_both_wins:DEFEATED]->(:Team)<-[t2_both_wins:DEFEATED]-(t2) 
optional match(t1)<-[t1_both_lost:DEFEATED]->(:Team)-[t2_both_lost:DEFEATED]->(t2) 
return t1.label, t1.pagerank,
length(collect(distinct(t11_wins))) as score1, 
t2.label, t2.pagerank,
length(collect(distinct(t21_wins))) as score2,
length(collect(distinct(t1_both_wins))) as both_won,
length(collect(distinct(t1_both_lost))) as both_lost