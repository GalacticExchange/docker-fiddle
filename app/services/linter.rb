class Linter
  require 'docker'
  require 'fileutils'
  require_relative 'docker_compose_parser'

  UNKNOWN_ERROR = [{
      line_number: 0,
      code: '',
      message: 'Unknown error occured',
      link: '#'
  }]

  @tmp_compose_path = '/tmp/'
  @tmp_compose_file_path= @tmp_compose_path + 'tmp_docker-compose.yml'
  def self.lint_dockerfile(dockerfile)

    File.open('/tmp/tmpLinterFile', 'w') do |f|
      f.puts dockerfile
    end

    puts dockerfile
    response = []
    linter_errors = %x[hadolint /tmp/tmpLinterFile]
    p linter_errors
    return [{line_number: 0, code: '', message: 'This Dockerfile is awesome!', link: '#'}] if linter_errors.empty?
    linter_errors = linter_errors.split "\n"
    linter_errors.each do |error|
      # puts error
      hash = Hash.new
      error.gsub! /\/tmp\/tmpLinterFile:?/, ''

      array = error.split(' ')
      if error.start_with? ' '
        hash[:line_number] = 0
        hash[:code] = array[0]
        hash[:message] = error[error.index(array[1])..-1]
      else
        hash[:line_number] = array[0]
        hash[:code] = array[1]
        hash[:message] = error[error.index(array[2])..-1]
      end

      if hash[:code].start_with? 'D'
        hash[:link] = "https://github.com/lukasmartinelli/hadolint/wiki/#{hash[:code]}"
      elsif hash[:code].start_with? 'S'
        hash[:link] = "https://github.com/koalaman/shellcheck/wiki/#{hash[:code]}"
      else
        hash[:line_number].gsub! /:.*/, ''
        hash[:link] = '#'
      end
      response << hash
    end
    response
  end

  def self.lint_compose(compose)
    puts compose.gsub(/#(.*)/,'')
    return [{line_number: 0, code: '', message: 'You can\'t check empty files!', link: '#'}] if compose.gsub(/#(.*)/,'').blank?
    response = []

    File.open(@tmp_compose_file_path, 'w') do |f|
      f.puts compose
    end

    folders = prepare_compose_folder

    linter_errors = %x[docker-compose -f #{@tmp_compose_file_path} config 2>&1 >/dev/null]
    p linter_errors

    folders.each do |folder|
      FileUtils.rm_rf(folder[:folder_path]) unless folder[:folder_path].eql? '/tmp'
    end

    return [{line_number: 0, code: '', message: 'This Compose file is awesome!', link: '#'}] if linter_errors.empty? and response.empty?

    errors_array = linter_errors.split("\n")
    p errors_array
    first_line = errors_array.delete_at(0)
    if first_line.match /is invalid because/
      errors_array.each do |error|
        tmp_error = error.clone
        if tmp_error.start_with? 'Unsupported config option for'
          tmp_error.gsub! 'Unsupported config option for ', ''
          tmp_error.gsub! ": '", '.'
          tmp_error.gsub! /'.*/, '.'
        elsif tmp_error =~ /^[\w]+\./
          tmp_error.gsub! /(\.[\w]+)[\s].*/, '\1'
        elsif tmp_error =~ /Service [\w]+ has neither/
          tmp_error = tmp_error.to_enum(:scan, /Service (?<service>[\w]+) has neither/)
                          .map { Regexp.last_match }
          tmp_error = tmp_error[0][:service]
        end
        tmp_error = tmp_error.split('.')
        response << {
            line_number: 0,
            code: '',
            message: error,
            link: '#',
            error_path: tmp_error
        }
      end
      response = find_error_lines(response)
    elsif first_line.match /ParserError/
      if first_line.match /block collection/
        line_n = errors_array[0].scan(/\d+/)[0].to_i
        response << {
            line_number: line_n,
            code: '',
            message: 'Inconsistency in collection',
            link: '#'
        }
      else
        return UNKNOWN_ERROR
      end
    elsif first_line.match /ComposerError/
      if first_line.match /expected a single/
        response << {
            line_number: 0,
            code: '',
            message: 'expected a single document in the stream',
            link: '#'
        }
      else
        return UNKNOWN_ERROR
      end
    elsif first_line.match /ScannerError/
      if first_line.match /simple key/
        line_n = errors_array[0].scan(/\d+/)[0].to_i
        response << {
            line_number: line_n,
            code: '',
            message: "Error occurred while scanning line #{line_n}",
            link: '#'
        }
      end
    elsif first_line.match /Top level object/
      return [{line_number: 0, code: '', message: 'Top level object in docker-compose.yml needs to be an object not type string', link: '#'}]
    else
      return UNKNOWN_ERROR
    end
    puts response
    response
  end



  private
    def self.find_error_lines(errors)
      puts errors
      errors.select! {|x| !x[:error_path][0].eql? 'volumes'}
      count = 1
      File.open(@tmp_compose_file_path, 'r') { |file| file.each_line { |line|
        line.strip!
        errors.each do |error|
          next unless error[:error_path]
          if line.start_with? error[:error_path][0]
            error[:error_path].delete_at(0)
            if error[:error_path].empty?
              error[:line_number] = count
              error.delete(:error_path)
            end
          end
        end
        count += 1
      }}
      errors
    end

    def self.prepare_compose_folder
      begin
        parser = DockerComposeParser.new(@tmp_compose_file_path)
        pathes = parser.get_dockerfile_pathes
        puts pathes
        pathes.each do |path|
          FileUtils.mkdir_p path[:folder_path]
          File.open(path[:file_path],'w') {|f| f.puts "FROM ubuntu:trusty\nCMD ls -lh"}
        end
        pathes
      rescue => e
        # puts e
        # puts e.backtrace
        []
      end
      # pathes = []
      # compose_lines.each do |line|
      #   line.strip!
      #   if line.start_with? 'build:'
      #     path = line.gsub 'build: ', ''
      #     if path.start_with? '.'
      #       path.gsub! '.', ''
      #       path = "#{@tmp_compose_path}#{path}"
      #       path.gsub '//', '/'
      #     end
      #     FileUtils.mkdir_p path
      #     File.open("#{path}Dockerfile")
      #     pathes << path
      #   end
      # end
      # pathes
    end
end


 # puts Linter.lint_compose(File.read('/home/iliya/Desktop/docekr-compose.yml'))