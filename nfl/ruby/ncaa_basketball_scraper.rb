require 'nokogiri'
require 'open-uri'
require 'active_support'
require 'active_support/all'
require 'date'

load "scraper.rb"

# docker cp ncaa ef939ac64992:/var/lib/neo4j/import/

class NcaaBasketballScraper < Scraper

  def initialize(season='2018_2019')
    @season = season 
    out_file_dir = "../../data/ncaa/#{@seasons}"
    super(out_file_dir)
  end

  def games_from_url(year:2018, month:11, day:6)
    month = month.to_s.rjust(2, '0')
    day = day.to_s.rjust(2, '0')
    out_file_path = "#{@out_file_dir}/basketball_results_#{year}-#{month}-#{day}.json"
    puts "Considering: #{out_file_path}"
    # return "#{year}-#{month}-#{day}" if File.exists?(out_file_path)
    return nil if File.exists?(out_file_path)
    url = "https://www.ncaa.com/scoreboard/basketball-men/d1/#{year}/#{month}/#{day}/all-conf"
    puts "Scraping: #{url}"
    doc = Nokogiri::HTML(open(url))
    games = doc.css("#scoreboardGames .gamePod.status-final")
    puts "Found #{games.length} games"
    games_array = games.map do |game|
      puts "+" * 50
      result = game.css("ul.gamePod-game-teams li").map do |team_result| 
        begin
            team = team_result.css(".gamePod-game-team-name").text 
            logo = team_result.css("img")[0]["src"]
            team_id = logo.split("/").last.split(".").first
            points = team_result.css(".gamePod-game-team-score").text
            {team_id: team_id, team: team.squish, logo: logo, points: points}
        rescue => e 
            nil
        end
      end.compact.presence
      puts result
      result
    end
    File.open(out_file_path, "w+") do |f|
      f.write(JSON.pretty_generate(games_array))
    end
    return "#{year}-#{month}-#{day}"
  end
end

scraper = NcaaBasketballScraper.new("2018_2019")
puts "Created new scraper..."
d = Date.parse("2018-11-06")
dates = []
while (d < Time.now.to_date)
    dates << scraper.games_from_url(year: d.year, month: d.month, day: d.day)
    d = d + 1
end
puts dates.compact.to_json
