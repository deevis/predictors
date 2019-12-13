require 'nokogiri'
require 'open-uri'
require 'active_support'
require 'active_support/all'
require 'pry'

load "scraper.rb"

class CbsSportsMlbScraper < Scraper
  @@url = "https://www.cbssports.com/mlb/scoreboard/_year_month_day_/"

  def initialize(year) 
    out_dir = "../data/mlb/#{year}"
    super(out_dir)
  end

  def games_from_url(year_month_day="20190907")
    out_file_path = "#{@out_file_dir}/mlb_results_#{year_month_day}.json"
    return if File.exists?(out_file_path)
    url = @@url.gsub("_year_month_day_", year_month_day)
    puts "Scraping: #{url}"
    doc = Nokogiri::HTML(open(url))
    games = doc.css(".score-card-container .single-score-card.postgame.mlb")
    puts "Found #{games.length} games"
    games_array = games.map do |game|
      puts "+" * 50
      result = game.css(".in-progress-table table tbody tr").map do |team_result| 
        begin
          team = team_result.css("td.team a.team").text 
          runs = team_result.css("td")[1].text
          hits = team_result.css("td")[2].text
          errors = team_result.css("td")[3].text
          {team: team.squish, runs: runs, hits: hits, errors: errors}
        rescue => e  
          puts e.message
          nil 
        end
      end.compact
      puts result
      result
    end
    File.open(out_file_path, "w") do |f|
      f.write(JSON.pretty_generate(games_array))
    end
  end
end

scraper = CbsSportsMlbScraper.new(2019)
day = Date.parse("2019-03-28")
while (day <  Time.now) do
  scraper.games_from_url(day.strftime("%Y%m%d"))
  day = day + 1.day
end
