require 'awesome_print'
require 'yaml'
load 'neo4j_query_service.rb'

year = 2022
total_pages = 0

# Find the total number of pages to process... (run premier_league_scraper.rb prior to this)
while (total_pages < 25) # don't check forever ya know
    file_path = File.join("..", "data" ,"premier_league", year.to_s, "results_#{year}_page_#{total_pages}.json")
    puts "Checking: #{file_path}  (exists #{File.exist?(file_path)})"
    if !File.exist?(file_path)
        total_pages = total_pages - 1
        break
    end
    total_pages += 1
end
raise "Invalid total_pages: #{total_pages}" if total_pages < 0 || total_pages >= 25

NQS.check_connection!

# start with the Premier League

#  [{"t.label"=>"Arsenal"}, {"t.label"=>"Chelsea"}]
teams = (NQS.run_cql("match(t:Team) return t.label") || []).map{|x| x['t.label']}

# Check teams (games?) are loaded
if teams.length == 0
    # load the file...
    NQS.run_file("../neo4j/load_premier_league_data.cql", total_pages: total_pages)
    teams = (NQS.run_cql("match(t:Team) return t.label") || []).map{|x| x['t.label']}
    raise "Unable to load teams into Neo4J" if teams.length == 0
end

# Check pagerank algo has been run
result = NQS.run_cql("match(t:Team{label: '#{teams[0]}'}) return t")
if result.first['t']['pagerank'].nil?
    # run the pagerank algo
    NQS.ensure_projection('predictions_default')
    NQS.run_file("../neo4j/run_pagerank.cql")
    result = NQS.run_cql("match(t:Team{label: '#{teams[0]}'}) return t")
    raise "Unable to run pagerank algo in Neo4J" if result.first['t']['pagerank'].nil?
end


standings = NQS.run_file("../neo4j/compute_standings.cql")
ap standings



