require 'fileutils'

module Caching
    def self.by_directory_params(cache_directory, params, cache_nil_results = true, &block)
      if cache_directory
        cached_file_name_hash = Hash[params.reject{|k,v| v.blank?}.stringify_keys.sort{|a,b| a[0] <=> b[0]}]
        cached_file_name = cached_file_name_hash.map do |k,v|
          if v.is_a?(Array)
            "#{k}::#{v.join('_')}"
          else
            "#{k}::#{v}"
          end
        end.join("__")
        if cached_file_name.gsub("/", "--").length > 250
          cached_file_name = cached_file_name.gsub("/", "--")[0..192]
        end
        cached_file_name = "#{cached_file_name.gsub("/", "--")}.json"
        cached_file_path = "#{cache_directory}/#{cached_file_name}"
  
        # For creating test case supporting data
        if (Thread.current[:test_cache_directory]).present?
          test_cache_directory = "#{Thread.current[:test_cache_directory]}/#{cache_directory.gsub('.','')}"
          FileUtils.mkdir_p("#{test_cache_directory}")
          test_cached_file_path = "#{test_cache_directory}/#{cached_file_name}"
          # puts "Checking for test file: #{test_cached_file_path}".yellow
          if File.exist?(test_cached_file_path)
            # puts "Returning search results from #{test_cached_file_path}".green
            data = JSON.parse(File.read(test_cached_file_path))
            return data
          else
            # byebug
            puts "Test file NOT FOUND: #{test_cached_file_path}".red
          end
        end
  
        FileUtils.mkdir_p(cache_directory)
        if File.exist?(cached_file_path)
          Rails.logger.info "Returning search results from #{cached_file_path}".yellow
          data = JSON.parse(File.read(cached_file_path))
          # For creating test case supporting data
          if test_cached_file_path.present? && !File.exist?(test_cached_file_path)
            puts "Writing test cache: #{test_cached_file_path}".yellow
            File.open(test_cached_file_path, "w") {|f| f.puts data.to_json }
          end
  
          return data
        end
      end
      # we didn't find the cached results, run our block
      data = block.call
      if cache_directory && (data.present? || cache_nil_results)
        Rails.logger.info "Writing cached result to #{cached_file_path}"
        File.open(cached_file_path, "w"){|f| f.puts data.to_json}
      elsif cache_directory.present?
        # Rails.logger.warn "Not writing cache file: cache_directory: #{cache_directory}"
        # Rails.logger.warn "                           data.present: #{data.present?}"
        # Rails.logger.warn "                      cache_nil_results: #{cache_nil_results}"
      end
      data
    end
  end