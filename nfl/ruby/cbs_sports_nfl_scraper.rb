require 'nokogiri'
require 'open-uri'
require 'active_support'
require 'active_support/all'

load "scraper.rb"

class CbsSportsNflScraper < Scraper
  @@url = "https://www.cbssports.com/nfl/scoreboard/all/_year_/regular/_week_/"

  def initialize(year=2022)
    @year = year
    out_file_dir = File.join("..", "data" ,"nfl", year)
    super(out_file_dir)
  end

  def games_from_url(week=1)
    out_file_path = File.join(out_file_dir, "nfl_results_#{@year}_week_#{week}.json")
    if File.exists?(out_file_path)
      puts "Skipping: #{out_file_path} as it already exists"
      return
    end
    url = @@url.gsub("_year_", @year.to_s).gsub("_week_", week.to_s)
    puts "Scraping: #{url}"
    doc = Nokogiri::HTML(URI.open(url))
    games = doc.css(".score-card-container .single-score-card.postgame.nfl")
    if games.length == 0 
      puts "Not creating file for week #{week} with 0 games"
      return 0
    end
    puts "Found #{games.length} games"

    games_array = games.map do |game|
      puts "+" * 50
      result = game.css(".in-progress-table table tbody tr").map do |team_result| 
        team = team_result.css("td.team a").last.text 
        points = team_result.css("td").last.text
        {team: team.squish, points: points}
      end
      puts result
      result
    end
    if week < 18 && games.length < 16
      puts "Not writing regular season file for week #{week} with only #{games.length} games (< 16)"
      return 0
    else
      puts "Writing #{games.length} to #{out_file_path}"
      File.open(out_file_path, "w") do |f|
        f.write(JSON.pretty_generate(games_array))
      end
      return games.length
    end
  end
end

scraper = CbsSportsNflScraper.new(ARGV[0])
last_week_loaded = 0
(0..26).each do |x| 
  break if scraper.games_from_url(x+1) == 0
  last_week_loaded = x + 1 
end
exit(last_week_loaded)

