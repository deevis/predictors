require 'awesome_print'
require 'yaml'
load 'neo4j_query_service.rb'

NQS.check_connection!

# start with the Premier League

#  [{"t.label"=>"Rams"}, {"t.label"=>"Falcons"}, {"t.label"=>"Panthers"}]
teams = (NQS.run_cql("match(t:Team) return t.label") || []).map{|x| x['t.label']}

# Check teams (games?) are loaded
if teams.length == 0
    # load the file...
    NQS.run_file("../neo4j/load_premier_league_data.cql")
    teams = (NQS.run_cql("match(t:Team) return t.label") || []).map{|x| x['t.label']}
    raise "Unable to load teams into Neo4J" if teams.length == 0
end

# Check pagerank algo has been run
result = NQS.run_cql("match(t:Team{label: '#{teams[0]}'}) return t")
if result.first['t']['pagerank'].nil?
    # run the pagerank algo
    NQS.run_file("../neo4j/run_pagerank.cql")
    result = NQS.run_cql("match(t:Team{label: '#{teams[0]}'}) return t")
    raise "Unable to run pagerank algo in Neo4J" if result.first['t']['pagerank'].nil?
end


standings = NQS.run_file("../neo4j/compute_standings.cql")
ap standings



