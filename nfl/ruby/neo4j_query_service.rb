require 'socket'
require 'uri'
require 'colored2'
require 'json'
require 'active_support/all'

load 'json_web_service.rb'

class Neo4jQueryService
 
    NEO4J_URL = "http://localhost:7474"  # HTTP interface
    ENV['NEO4J_USERNAME'] = 'neo4j'
    ENV['NEO4J_PASSWORD'] = 'letmein'

    def self.check_connection!(tries: 1)
      if ENV['BYPASS_CHECKS'] == 'true'
        puts "Not checking Neo4J connection as ENV['BYPASS_CHECKS']=='true'".yellow
        return
      end
      url = NEO4J_URL
      url ||= "http://localhost:7475"
      jws = JsonWebService.new(endpoint: "#{url}/db/data/transaction/commit",
          headers: { 'Accept-Encoding' => 'application/json', 'Content-Type' => 'application/json'})
      puts "Checking Neo4j installation at: #{url}".yellow
  
      uri = URI(url)
      host = uri.host
      port = uri.port
      count = 0
      available = false
      while (!available && count < tries)
        available = Socket.tcp(host, port, connect_timeout: 1) { true } rescue false
  
        if !available
          if count == 0
            puts "Current docker containers (jic):"
            docker_results = `docker ps`
            puts docker_results
          end
          count += 1
          puts "(#{count}/#{tries}) Waiting for socket to be available at: #{url}".cyan
          sleep 2
        end
      end
      responding = false
      while (available && !responding && count < tries)
        call_params = {"statements":[{"statement": 'match(n) return n limit 1',
                      "resultDataContents":['row']}]}
        result = jws.call(params: JSON.dump(call_params), method: :post)
        if result.nil?
          count += 1
          puts "(#{count}/#{tries}) Waiting for response from: #{url}".cyan
          sleep 3
        else
          responding = true
        end
      end
      if !available || !responding
        puts "Unable to connect to Neo4j at: #{url}".red
        raise "Unable to connect to Neo4J at: #{url}"
      end
      puts "Successfully connected to Neo4J at #{url}".green
      neo4j_stats = run_cql(
        "call dbms.components() yield name, versions, edition unwind versions
          as version return name, version, edition;", result_data_contents: 'row')
      apoc_version = run_cql("return apoc.version()", result_data_contents: 'row') rescue "N/A"
      gds_version = run_cql("return gds.version()", result_data_contents: 'row') rescue "N/A"
      algo_version = run_cql("return algo.version()", result_data_contents: 'row') rescue "N/A"
      puts "NEO4J Stats: #{neo4j_stats}".cyan
      puts "APOC: #{apoc_version}".cyan
      puts "ALGO: #{algo_version}".cyan
      puts "GDS: #{gds_version}".cyan
    end
  
    # result_data_contents: ['graph' | 'row']
    # return_hashes - only applies to result_data_contents = 'row'
    def self.run_cql(query, result_data_contents: 'row', return_hashes: true)
      result_data_contents ||= "graph"
      call_params = {"statements":[{"statement": query,
                    "resultDataContents":[result_data_contents]}]}
      jws = JsonWebService.new(endpoint: "#{NEO4J_URL}/db/data/transaction/commit",
        headers: { 'Accept-Encoding' => 'application/json', 'Content-Type' => 'application/json'})
      # You need to JSON.dump the call_params or else we'll get:
      #     Unable to deserialize request: Unexpected character...
      start = Time.now
      result = jws.call(params: JSON.dump(call_params), method: :post)
      if result
        if (errors = result["errors"]).present?
          error_messages = errors.map{|e| "#{e['code']} : #{e['message']}"}
          raise error_messages.join("\n")
        end
        if result_data_contents == 'row' && return_hashes
          # Convert this to an array of Hashes
          columns = result["results"][0]["columns"]
          data = result["results"][0]["data"].map{|item| item['row'] }
          result = data.map{|item| Hash[columns.zip(item)]}
        end
      end
      return result
    ensure
      if result.present?
        collect_cql_activity(query, result_count: result.length,  duration: Time.now - start, error_messages: error_messages)
      else
        # noop?
      end
    end
  
    def self.ensure_projection(projection_name)
      remove_projection = <<~CQL
        CALL gds.graph.drop('#{projection_name}', false) YIELD graphName
      CQL

      create_projection = <<~CQL
        CALL gds.graph.project('#{projection_name}','Team','EARNED_POINT')
        YIELD graphName AS graph, nodeProjection, nodeCount AS nodes, relationshipProjection, relationshipCount AS rels
      CQL

      run_cql(remove_projection)
      run_cql(create_projection)
    end

    def self.run_file(filepath, template_params={})
        # puts "Running file: #{filepath}"
        cql = File.readlines(filepath)
        template_params.each do |param_name, param_value|
          replace_this = "__#{param_name}__"
          # puts "Replacing #{replace_this} with #{param_value}"
          cql = cql.map do |line|
            puts "#{line.class}: #{line}"
            line.gsub(replace_this, param_value.to_s)
          end
        end
        puts "-" * 60
        puts "RUNNING CQL".cyan
        puts "-" * 60
        puts cql.join
        # cql.reject!{|l| l.squish.start_with?("//")}
        result = NQS.run_cql(cql.join) 
        ap result
        puts "-" * 60
        puts "RUNNING CQL".cyan
        puts "-" * 60
        result
    end

    def self.collect_cql_activity(cql, result_count:, duration:, error_messages:)
      if !Thread.current[:cql_activity].nil?
        Thread.current[:cql_activity] << { cql: cql, result_count: result_count,
                                      duration: duration, error_messages: error_messages}
      end
    end
  
    def self.capture_cql(&proc)
      if (b4 = Thread.current[:cql_activity]).nil?
        # create our ThreadLocal if it is not currently set
        Thread.current[:cql_activity] = []
      end
      return yield
    ensure
      # clear our ThreadLocal if we created it
      if b4.nil?
        Thread.current[:cql_activity] = nil
      end
    end
  
    def self.retrieve_captured_cql
      Thread.current[:cql_activity]
    end
  end

  NQS = Neo4jQueryService