require 'nokogiri'
require 'open-uri'
require 'active_support'
require 'active_support/all'

load "scraper.rb"

class CbsSportsNcaaFootballScraper < Scraper
  @@url = "https://www.cbssports.com/college-football/scoreboard/FBS/_year_/regular/_week_/"

  def initialize(year=2018) 
    @year = year 
    @season = "#{year}_#{year+1}"
    out_file_dir = "../data/ncaa_cbs/#{@season}/football"
    super(out_file_dir)
  end

  def games_from_url(week=1)
    year = @year
    out_file_path = "#{@out_file_dir}/ncaa_results_#{year}_week_#{week}.json"
    return if File.exists?(out_file_path)
    url = @@url.gsub("_year_", year.to_s).gsub("_week_", week.to_s)
    puts "Scraping: #{url}"
    doc = Nokogiri::HTML(open(url))
    games = doc.css(".score-card-container .single-score-card.postgame.collegefootball")
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
    File.open(out_file_path, "w") do |f|
      f.write(JSON.pretty_generate(games_array))
    end
  end
end

scraper = CbsSportsNcaaFootballScraper.new(2018)
(0..13).each do |x| 
  scraper.games_from_url(x+1)
end
