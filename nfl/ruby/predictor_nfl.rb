require 'awesome_print'
require 'yaml'
load 'neo4j_query_service.rb'

year = 2022
week = 0

# Find the most recent week to predict... (run nfl_com_scraper.rb prior to this)
while (week < 25) # don't check forever ya know
    file_path = File.join("..", "data" ,"nfl", year.to_s, "nfl_com_results_#{year}_week_#{week+1}.json")
    puts "Checking: #{file_path}  (exists #{File.exist?(file_path)})"
    if !File.exist?(file_path)
        file_path = File.join("..", "data" ,"nfl", year.to_s, "nfl_com_results_#{year}_week_#{week}.json")
        break
    end
    week += 1
end
raise "Invalid week: #{week}" if week < 1 || week > 25
NQS.check_connection!

# start with the NFL

#  [{"t.label"=>"Rams"}, {"t.label"=>"Falcons"}, {"t.label"=>"Panthers"}]
teams = (NQS.run_cql("match(t:Team) return t.label") || []).map{|x| x['t.label']}

# Check teams (games?) are loaded
if teams.length == 0
    # load the file...
    NQS.run_file("../neo4j/load_nfl_com_data.cql", week_number: week)
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

# [
#     [ 0] {
#                 "team" => "Eagles",
#         "power_rating" => 5.355,
#             "pagerank" => 0.873,
#         "opp_pagerank" => 0.43,
#               "vp_avg" => 2.0,
#               "points" => 4,
#                 "wins" => 2,
#               "losses" => 0,
#                 "ties" => 0,
#              "crushes" => 0,
#          "trainwrecks" => 0,
#              "margins" => [
#             [0] 3,
#             [1] 17
#         ]
#     },
standings = NQS.run_file("../neo4j/compute_standings.cql")

puts "Predicting week #{week} games from: #{file_path}"
sleep(1.5)
j = JSON.parse(File.readlines(file_path).join()) rescue nil
if j.present?
    predict_these = j['games'].select{|g| g.dig('detail', 'quarter') != 'END_OF_GAME'}.map do |g|
        homeTeam = g.dig('homeTeam', 'nickName')
        homeStats = standings.detect{|s| s['team'] == homeTeam} rescue nil
        raise "Couldn't find standings for #{homeTeam}" if homeStats.nil?
        awayTeam = g.dig('awayTeam', 'nickName')
        awayStats = standings.detect{|s| s['team'] == awayTeam} rescue nil
        raise "Couldn't find standings for #{awayTeam}" if awayStats.nil?
        if homeStats['power_rating'] > awayStats['power_rating']
            winner = homeTeam
            power_margin = homeStats['power_rating'] - awayStats['power_rating']
        else
            winner = awayTeam
            power_margin = awayStats['power_rating'] - homeStats['power_rating']
        end
        {
            winner: winner, 
            homeTeam: homeTeam, homeStats: homeStats, 
            awayTeam: awayTeam, awayStats: awayStats, 
            power_margin: power_margin
        }
    end
    ap predict_these
    File.open("predictions/nfl/#{year}/week#{week}.yaml", 'w') do |f|
        data = {week: week, year: year, predictions: predict_these}
        f.puts data.to_yaml
    end

    puts "=" * 60
    puts "Predictions week #{week} of #{year} Season"
    puts "=" * 60
    predict_these.each do |p|
        [:home, :away].each do |t|
            team = p["#{t}Team".to_sym]
            stats = p["#{t}Stats".to_sym]
            print team.rjust(20, " ")
            print " (#{stats['wins']}-#{stats['losses']}-#{stats['ties']}) "
            print p["#{t}Stats".to_sym]['power_rating']
             if team == p[:winner]
                puts "  WINNER  (#{p[:power_margin].round(3)})" 
            else
                puts "          "
            end
           
        end
        print "-" * 60
        puts "\n"
    end

end


