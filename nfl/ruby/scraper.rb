require 'active_support/all'

class Scraper

    attr_accessor :out_file_dir

    def initialize(out_file_dir)
        @out_file_dir = out_file_dir
        FileUtils.mkdir_p @out_file_dir
    end
  
end
