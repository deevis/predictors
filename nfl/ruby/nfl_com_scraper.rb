
require 'active_support'
require 'active_support/all'
require 'shellwords'
require 'fileutils'

load "scraper.rb"

class NflComScraper < Scraper
  @@url = "https://api.nfl.com/experience/v1/games?season=_year_&seasonType=REG&week=_week_"

  def initialize(year=2022)
    @year = year
    out_file_dir = File.join("..", "data" ,"nfl", year.to_s)
    # something like this:
    # @bearer_token = "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjbGllbnRJZCI6ImU1MzVjN2MwLTgxN2YtNDc3Ni04OTkwLTU2NTU2ZjhiMTkyOCIsImNsaWVudEtleSI6IjRjRlVXNkRtd0pwelQ5TDdMckczcVJBY0FCRzVzMDRnIiwiaXNzIjoiTkZMIiwiZGV2aWNlSWQiOiI1MTBmMDU2YS1kYTc0LTQ5MWMtYjJmYy0xMmZhZjhlNzA2ZTMiLCJwbGFucyI6W3siZXhwaXJhdGlvbkRhdGUiOiIyMDIzLTA5LTE4IiwicGxhbiI6ImZyZWUiLCJzb3VyY2UiOiJORkwiLCJzdGFydERhdGUiOiIyMDIyLTA5LTE4Iiwic3RhdHVzIjoiQUNUSVZFIiwidHJpYWwiOiJmYWxzZSJ9XSwiRGlzcGxheU5hbWUiOiJXRUJfREVTS1RPUF9ERVNLVE9QIiwiTm90ZXMiOiIiLCJmb3JtRmFjdG9yIjoiREVTS1RPUCIsImx1cmFBcHBLZXkiOiJTWnM1N2RCR1J4Ykw3MjhsVnA3RFlRIiwicGxhdGZvcm0iOiJERVNLVE9QIiwicHJvZHVjdE5hbWUiOiJXRUIiLCJjb3VudHJ5Q29kZSI6IlVTIiwiZG1hQ29kZSI6Ijc3MCIsImhtYVRlYW1zIjpbIjEwNDAxNDAwLWI4OWItOTZlNS01NWQxLWNhYTdlMThkZTNkOCIsIjEwNDAyNTEwLTg5MzEtMGQ1Zi05ODE1LTc5YmI3OTY0OWE2NSIsIjEwNDAyNTIwLTk2YmYtZTlmMi00ZjY4LTg1MjFjYTg5NjA2MCIsIjEwNDA0NDAwLTNiMzUtMDczZi0xOTdlLTE5NGJiODI0MDcyMyJdLCJicm93c2VyIjoiQ2hyb21lIiwiY2VsbHVsYXIiOmZhbHNlLCJlbnZpcm9ubWVudCI6InByb2R1Y3Rpb24iLCJleHAiOjE2NjM0OTE5MTB9.kpxq0mjujToW_4sDGNUYc_srkRz4o_B_qDUujaG7ccA"
    @bearer_token = nil
    super(out_file_dir)
  end

  def get_bearer_token
    return @bearer_token if @bearer_token.present?
    puts "Enter the bearer token AUTH header from nfl.com/scores for ajax request nfl.com/games"
    @bearer_token = STDIN.gets.strip
    puts "\n\nGot bearer token of type #{@bearer_token.class}\n"
    puts "=" * 50
    puts @bearer_token
    puts "=" * 50
    @bearer_token
end

  def games_from_url(week=1)
    out_file_path = "#{@out_file_dir}/nfl_com_results_#{@year}_week_#{week}.json"
    if File.exist?(out_file_path)
        # check if all games completed...
        j = JSON.parse(File.readlines(out_file_path).join()) rescue nil
        if j.present? && j['games'].map{|g| g.dig('detail', 'quarter') || 'N/A'}.uniq == ['END_OF_GAME']
            puts "Skipping existing: #{out_file_path}"
            return
        end
        puts "Re-downloading data for #{out_file_path}"
    end
    url = @@url.gsub('_week_', week.to_s).gsub('_year_', @year.to_s)
    puts "Preparing to scrape: #{url}"
    bearer_token = get_bearer_token
    return 0 if bearer_token.length < 10 # quit, stop, return - not a real token!
    curl_command = <<~CURL
        curl -k "#{url}" \
        -H 'authority: api.nfl.com' \
        -H 'accept: */*' \
        -H 'accept-language: en-US,en;q=0.8' \
        -H 'authorization: #{bearer_token}' \
        -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36' \
        -H 'origin: https://www.nfl.com' \
        -H 'referer: https://www.nfl.com/' \
        -H 'sec-fetch-dest: empty' \
        -H 'sec-fetch-mode: cors' \
        -H 'sec-fetch-site: same-site' \
        -H 'sec-gpc: 1' -o #{out_file_path}
    CURL
    puts "\n\nRunning curl command: \n\n#{curl_command}\n\n"
    `#{curl_command}`
    begin
        j = JSON.parse(File.readlines(out_file_path).join())
        completed_game_count = j['games'].select{|g| g.dig('detail', 'quarter') == 'END_OF_GAME'}.length 
        if completed_game_count < j['games'].length
            puts "Incomplete week (#{completed_game_count}/#{j['games'].length} games completed)"
            puts "Not deleting incomplete file (as it contains upcoming games to predict!): #{out_file_path}"
            # FileUtils.rm(out_file_path)
            return 0
        end
        return completed_game_count
    rescue => e
        puts "Couldn't parse #{out_file_path} - deleting invalid file"
        FileUtils.rm(out_file_path)
        return 0
    end
  end
end

scraper = NflComScraper.new(ARGV[0] || 2022)
last_week_loaded = 0
(0..26).each do |x| 
  break if scraper.games_from_url(x+1) == 0
  last_week_loaded = x + 1 
end
`cp #{scraper.out_file_dir}/* ../neo4j/data`
exit(last_week_loaded)

