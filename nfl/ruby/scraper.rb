class Scraper

    attr_accessor :out_file_dir

    def initialize(out_file_dir)
        @out_file_dir = out_file_dir
        `mkdir -p #{@out_file_dir}`
    end
  
end
