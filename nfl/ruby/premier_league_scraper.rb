# require 'rest-client'
# seasons = JSON.parse(RestClient.get("https://footballapi.pulselive.com/football/seasons?pageSize=100"))
# year = "2019"
# season = seasons["content"].detect{|s| s["label"].start_with?("Season #{year}")}
# # {"label"=>"Season 2019/2020", "id"=>28.0}
load "scraper.rb"

class PremierLeagueScraper < Scraper
    def initialize(year=2022)
        @year = year
        out_file_dir = File.join("..", "data" ,"premier_league", year.to_s)
        super(out_file_dir)
    end

    def games_from_url(week = :unused)
        teams = get_teams

        # games
        seasonId = 489
        team_ids = teams.map{|t| t['id'].to_i}
        games = []

        page = 0
        page_size = 40
        total_pages = nil # we'll get this after our first call in the 'pageInfo' section

        while ( total_pages.nil? || page < total_pages ) do
            out_file_path = "#{@out_file_dir}/results_#{@year}_page_#{page}.json"
            endpoint = "https://footballapi.pulselive.com/football/fixtures"


            dynamic_params = "&compSeasons=#{seasonId}&teams=#{team_ids.join(',')}&page=#{page}&pageSize=#{page_size}"
            fixtures_curl = <<~CURL
                curl "#{endpoint}?comps=1#{dynamic_params}&sort=asc&statuses=C&altIds=true" \
                -H 'Referer: https://www.premierleague.com/results' \
                -H 'Origin: https://www.premierleague.com' \
                --compressed
            CURL
            puts "Retrieving page #{page} from #{endpoint}"
            puts "-" * 60
            puts fixtures_curl
            puts "-" * 60
            fixtures_json = `#{fixtures_curl}`
            fixtures = JSON.parse(fixtures_json)

            # fixtures['pageInfo']
            # => {"page"=>1, "numPages"=>2, "pageSize"=>40, "numEntries"=>74}
            total_pages = fixtures['pageInfo']['numPages']

            parsed = fixtures['content'].map do |game|
                raw_date = game.dig('kickoff', 'label')
                date = Date.parse(raw_date).strftime("%Y-%m-%d") rescue raw_date
                h = { game_id: game['id'].to_i,
                    date: date,
                    week: game.dig('gameweek', 'gameweek')
                    }
                %w[home away].each_with_index do |home_or_away, idx|
                    info = game['teams'][idx]
                    h["#{home_or_away}_team"] = info.dig('team', 'name')
                    h["#{home_or_away}_score"] = info['score'].to_i
                end
                h.merge!(game.slice('extraTime', 'shootout', 'neutralGround', 'status', 'phase', 'outcome'))
                h
            end
            puts "Parsed #{parsed.length} games..."
            if parsed.length > 0
                File.open(out_file_path, "w") {|f| f.puts parsed.to_json}
            end
            games += parsed
            page += 1
        end
    end
    
    def get_teams
        # teams
        team_curl = <<~CURL
        curl 'https://footballapi.pulselive.com/football/compseasons/489/teams' \
        -H 'authority: footballapi.pulselive.com' \
        -H 'accept: */*' \
        -H 'accept-language: en-US,en;q=0.9,da;q=0.8' \
        -H 'account: premierleague' \
        -H 'cache-control: no-cache' \
        -H 'content-type: application/x-www-form-urlencoded; charset=UTF-8' \
        -H 'origin: https://www.premierleague.com' \
        -H 'pragma: no-cache' \
        -H 'referer: https://www.premierleague.com/' \
        -H 'sec-ch-ua: "Chromium";v="106", "Google Chrome";v="106", "Not;A=Brand";v="99"' \
        -H 'sec-ch-ua-mobile: ?0' \
        -H 'sec-ch-ua-platform: "Windows"' \
        -H 'sec-fetch-dest: empty' \
        -H 'sec-fetch-mode: cors' \
        -H 'sec-fetch-site: cross-site' \
        -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36' \
        --compressed
        CURL
        
        teams_json = `#{team_curl}`
        
        require 'json'
        teams = JSON.parse(teams_json)
        
        # ap teams[0]
        # {
        #          "name" => "AFC Bournemouth",
        #          "club" => {
        #              "name" => "Bournemouth",
        #         "shortName" => "Bournemouth",
        #              "abbr" => "BOU",
        #                "id" => 127.0
        #     },
        #      "teamType" => "FIRST",
        #       "grounds" => [
        #         [0] {
        #                 "name" => "Vitality Stadium",
        #                 "city" => "Bournemouth",
        #             "capacity" => 11464.0,
        #             "location" => {
        #                  "latitude" => 50.7349,
        #                 "longitude" => -1.83899
        #             },
        #               "source" => "OPTA",
        #                   "id" => 914.0
        #         }
        #     ],
        #     "shortName" => "Bournemouth",
        #            "id" => 127.0
        # }
    end
end    

scraper = PremierLeagueScraper.new(ARGV[0] || 2022)
scraper.games_from_url
