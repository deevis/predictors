require 'nokogiri'
require 'open-uri'
require 'active_support'
require 'active_support/all'
require 'pry'

load "scraper.rb"

class NcaaFootballScraper < Scraper

  def initialize(year=2019)
    @year = year
    @url = "https://www.ncaa.com/scoreboard/football/fbs/_year_/_week_/all-conf"
    super( "../data/ncaa/#{year}_#{year + 1}/football")
  end

  def games_from_url(week = 1)
    year = @year
    out_file_path = "#{@out_file_dir}/ncaa_results_#{year}_week_#{week}.json"
    return if File.exists?(out_file_path)
    url = @url.gsub("_year_", year.to_s).gsub("_week_", week.to_s.rjust(2, '0'))
    puts "Scraping: #{url}"
    doc = Nokogiri::HTML(open(url))
    games = doc.css("#scoreboardGames .gamePod.status-final")
    puts "Found #{games.length} games"
    games_array = games.map do |game|
      puts "+" * 50
      result = game.css("ul.gamePod-game-teams li").map do |team_result| 
        team = team_result.css(".gamePod-game-team-name").text 
        logo = team_result.css("img")[0]["src"]
        team_id = logo.split("/").last.split(".").first
        points = team_result.css(".gamePod-game-team-score").text
        {team_id: team_id, team: team.squish, logo: logo, points: points}
      end
      puts result
      result
    end
    File.open(@out_file_path, "w") do |f|
      f.write(JSON.pretty_generate(games_array))
    end
  end
end

scraper = NcaaFootballScraper.new(2019)
(0..1).each do |x| 
  scraper.games_from_url(x+1)
end
