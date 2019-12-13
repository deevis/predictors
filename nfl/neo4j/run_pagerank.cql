CALL algo.pageRank(
"MATCH (t:Team) WHERE exists( (t)-[:EARNED_POINT]-() ) RETURN id(t) as id",
"MATCH (t1:Team)-[b:EARNED_POINT]->(t2:Team) where b.date < '2018-12-15' RETURN id(t1) as source, id(t2) as target",
{graph:'cypher', iterations: 100, dampingFactor: 0.85, write: true, writeProperty:"start_pagerank"}
) YIELD nodes, iterations, loadMillis, computeMillis, writeMillis, dampingFactor, write, writeProperty
with 1 as asdf
CALL algo.pageRank(
"MATCH (t:Team) WHERE exists( (t)-[:EARNED_POINT]-() ) RETURN id(t) as id",
"MATCH (t1:Team)-[b:EARNED_POINT]->(t2:Team) where b.date >= '2018-12-15' and b.date < '2019-01-15' RETURN id(t1) as source, id(t2) as target",
{graph:'cypher', iterations: 100, dampingFactor: 0.9, write: true, writeProperty:"previous_pagerank"}
) YIELD nodes, iterations, loadMillis, computeMillis, writeMillis, dampingFactor, write, writeProperty
with 1 as asdf2
CALL algo.pageRank(
"MATCH (t:Team) WHERE exists( (t)-[:EARNED_POINT]-() ) RETURN id(t) as id",
"MATCH (t1:Team)-[b:EARNED_POINT]->(t2:Team) where b.date >= '2019-01-15' RETURN id(t1) as source, id(t2) as target",
{graph:'cypher', iterations: 100, dampingFactor: 0.9, write: true, writeProperty:"recent_pagerank"}
) YIELD nodes, iterations, loadMillis, computeMillis, writeMillis, dampingFactor, write, writeProperty
with 1 as asdf3
CALL algo.pageRank(
"MATCH (t:Team) WHERE exists( (t)-[:EARNED_POINT]-() ) RETURN id(t) as id",
"MATCH (t1:Team)-[b:EARNED_POINT]->(t2:Team) RETURN id(t1) as source, id(t2) as target",
{graph:'cypher', iterations: 100, dampingFactor: 0.9, write: true, writeProperty:"pagerank"}
) YIELD nodes, iterations, loadMillis, computeMillis, writeMillis, dampingFactor, write, writeProperty
return nodes, iterations, loadMillis, computeMillis, writeMillis, dampingFactor, write, writeProperty

// CALL algo.pageRank(
// "MATCH (t:Team) WHERE exists( (t)-[:BEATEN_BY]-() ) RETURN id(t) as id",
// "MATCH (t1:Team)-[b:BEATEN_BY]->(t2:Team) RETURN id(t1) as source, id(t2) as target",
// {graph:'cypher', iterations: 100, dampingFactor: 0.85, write: true, writeProperty:"pagerank"}
// ) YIELD nodes, iterations, loadMillis, computeMillis, writeMillis, dampingFactor, write, writeProperty

