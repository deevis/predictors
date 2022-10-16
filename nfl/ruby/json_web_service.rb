require 'typhoeus'
load 'caching.rb'
require 'base64'

class JsonWebService

    attr_reader :endpoint
    attr_reader :cache_directory
  
    def initialize(endpoint: , headers: nil, cache_directory: nil, cache_nil: true, upcased_params: false)
      @endpoint = endpoint
      @headers = headers
      @cache_directory = cache_directory
      @cache_nil = cache_nil
      @upcased_params = upcased_params
    end
  
    # result_extractor_block:
    #     Call with a block to that will take the search_result and convert it to the desired result format
    def call(params:, method: :post, caching_params: nil)
      start_time = Time.now
      params = params.with_upcased_strings if @upcased_params
      caching_params = caching_params.with_upcased_strings if caching_params
      caching_params ||= params
      if @endpoint.include? 'db/data/transaction/commit'
        if ENV["NEO4J_USERNAME"].present? && ENV["NEO4J_PASSWORD"].present?
          auth = "#{ENV['NEO4J_USERNAME']}:#{ENV['NEO4J_PASSWORD']}"
          encoded_auth = Base64.strict_encode64(auth)
          @headers['Authorization'] = "Basic #{encoded_auth}"
        end
      end
      result = Caching.by_directory_params(@cache_directory, caching_params, @cache_nil) do
        case method
        when :get, 'get', 'GET'
          url = @endpoint.index("?") ? "#{@endpoint}&" : "#{@endpoint}?"
          params.keys.each do |k|
            next if params[k].blank?
            val = params[k]
            val = val.gsub(" ", "+") if val.is_a?(String)
            url = "#{url}#{k}=#{val}&"
          end
          Rails.logger.debug {"JsonWebService[#{@endpoint}][GET] - #{url}".yellow}
          if @headers.present?
            response = Typhoeus.get(url, followlocation: true, headers: @headers)
          else
            response = Typhoeus.get(url, followlocation: true)
          end
        when :post, 'post', 'POST'
          url = @endpoint
         puts "JsonWebService[#{@endpoint}][POST] - #{params}".yellow
          if @headers.present?
            puts "Including headers: #{@headers}"
            response = Typhoeus.post(@endpoint, followlocation: true, body: params, headers: @headers)
          else
            response = Typhoeus.post(@endpoint, followlocation: true, body: params)
          end
        end
  
        case response.code
        when 200, 201
          JSON.parse(response.body)
        else
          nil
        end
      end
      puts "JsonWebService - completed in #{Time.now - start_time} seconds"
      result
    end
  end