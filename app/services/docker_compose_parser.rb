require 'yaml'
require 'find'
#require_relative 'docker_builder'

class DockerComposeParser
  attr_accessor :compose_file, :repository_name, :environment, :replacements

  def initialize(compose_filepath, repo_name='')
    @compose_filepath = compose_filepath
    @dockerfile_pathes = []
    @repo_folder = File.dirname compose_filepath
    @repo_folder << '/'
    @env_file_path = "#{@repo_folder}/.env"
    @repository_name = repo_name.gsub('/','_').downcase
    @compose_file = DockerCompose.new(compose_filepath)
    @environment = {}
    @containers = {}
    @replacements = {} # TODO decide if I need this
    @dockerfiles = []
  end

  def get_dockerfile_pathes
    @compose_file.each_service do |service|
      if service.build?
        build = service.build
        if build.instance_of?(Hash)
          context = build['context']
          if context.start_with? '.'
            context = '' if context.eql? './'
            context.gsub!(/\A\./, '')
          end
          folder_path = "#{@repo_folder}#{context}"
          file_path = "#{@repo_folder}#{context}/#{build['dockerfile']}"
        else
          build.strip!
          if build.start_with? '.'
            build = '' if build.eql? './'
            build.gsub!(/\A\./, '')
          end
          context = build
          folder_path = "#{@repo_folder}#{context}"
          if service.dockerfile?
            dockerfile = service.dockerfile.gsub(/\A\.?\/?/,'')
            file_path = "#{@repo_folder}#{context}/#{dockerfile}"
          else
            file_path = "#{@repo_folder}#{context}/Dockerfile"
          end
        end
        @dockerfile_pathes << {
            folder_path: folder_path,
            file_path: file_path
        }
      end
    end
    @dockerfile_pathes
  end
  
  def check_for_build
    @compose_file.each_service do |service|
      if service.build?
        build = service.build
        if build.instance_of?(Hash)
          context = build['context']
          if context.start_with? '.'
            context = '' if context.eql? './'
            context.gsub!(/\A\./, '')
          end
          @dockerfiles << {
              :service => service.name,
              :text => File.read("#{@repo_folder}#{context}/#{build['dockerfile']}")
          }
          # name = generate_image_name(service, context.gsub('/','_'))
          # builder = DockerBuilder.new(:path => "#{@repo_folder}#{context}", :dockerfile_name => build['dockerfile'], :name => name)
          # builder.build
          # service.image = "#{DockerBuilder::REPO_ADDRESS}:#{name}"
          # service.remove_build!
        else

          build.strip!
          if build.start_with? '.'
            build = '' if build.eql? './'
            build.gsub!(/\A\./, '')
          end
          context = build
          begin
            text = File.read("#{@repo_folder}#{context}/Dockerfile")
          rescue => e
            if service.dockerfile?
              dockerfile = service.dockerfile.gsub(/\A\.?\/?/,'')
              text = File.read("#{@repo_folder}#{context}/#{dockerfile}")
            else
              text = 'ERROR OCCURED'

              p e
            end
          end
          @dockerfiles << {
              :service => service.name,
              :text => text
          }
          # name = generate_image_name(service, build.gsub('/','_'))
          # builder = DockerBuilder.new(:path => "#{@repo_folder}#{build}", :name => name)
          # builder.build
          # service.image = "#{DockerBuilder::REPO_ADDRESS}:#{name}"
          # service.remove_build!
          # TEST COMMENT1 docker_compose_parser.rb
        end
      end
    end
    @dockerfiles.clone
  end

  def get_services
    @services = {}
    @compose_file.each_service do |service|
      @services[service.name] = {}

      # port extraction
      service_ports = {}
      if service.ports?
        service.ports.each_with_index do |port, index|
          puts service.ports.class
          puts port.class
          case port
            when Hash
              if port['mode'].eql? 'host'
                port = port['target']
                if port.eql? '80' or port.eql? '8080'
                  protocol = 'http'
                elsif port.eql? '22'
                  protocol = 'ssh'
                else
                  protocol = ''
                end
                service_ports["#{service.name}_#{index}"] = {
                    name: "#{service.name}_#{index}",
                    protocol: protocol,
                    port: port['target']
                }
              else
                puts port['mode']
                puts 'Port mode is not eql to host!'
              end
            when String
              if port.scan(/:/).count > 1
                first_index = port.index(':') + 1
                last_index = port.rindex(':') - 1
                port = port[first_index..last_index]
                if port.eql? '80' or port.eql? '8080'
                  protocol = 'http'
                elsif port.eql? '22'
                  protocol = 'ssh'
                else
                  protocol = ''
                end
                service_ports["#{service.name}_#{index}"] = {
                    name: "#{service.name}_#{index}",
                    protocol: protocol,
                    port: port
                }
              elsif port.scan(/:/).count == 1
                port = port.gsub(/(:.*)/, '')
                if port.eql? '80' or port.eql? '8080'
                  protocol = 'http'
                elsif port.eql? '22'
                  protocol = 'ssh'
                else
                  protocol = ''
                end
                service_ports["#{service.name}_#{index}"] = {
                    name: "#{service.name}_#{index}",
                    protocol: protocol,
                    port: port
                }
              else
                if port.eql? '80' or port.eql? '8080'
                  protocol = 'http'
                elsif port.eql? '22'
                  protocol = 'ssh'
                else
                  protocol = ''
                end
                service_ports["#{service.name}_#{index}"] = {
                    name: "#{service.name}_#{index}",
                    protocol: protocol,
                    port: port
                }
              end
            else
              puts 'What are you?'
              puts 'I am ' << port.class.to_s
          end
        end
      end

      @services[service.name] = service_ports.clone
      p service
    end
    @services
  end

  def get_containers
    @compose_file.each_service do |service|
      @containers[service.name] = {}
      if service.build?
        build = service.build
        case build
          when Hash
            build['dockerfile'] = 'Dockerfile' unless build['dockerfile']
            build[:type] = 'build'
            @containers[service.name][:build] = build.clone
          when String
            new_build = {
                type: 'build',
                context: build.clone,
                dockerfile: 'Dockerfile'
            }
            @containers[service.name][:build] = new_build.clone
          else
            raise StandardError.new("The service #{service.name} build is present, but is neither a Hash, nor String, it's #{build.class}")
        end
      end

      if service.image? and !service.build?
        hash = {
            type: 'image',
            image: service.image.clone
        }
        @containers[service.name][:build] = hash.clone
      end

      # include everything except listed
      service.yml[1].each do |key,value|
        next if %w(ports environment image container_name build env_file).include? key
        @containers[service.name][key] = value
      end
    end
    @containers
  end

  def check_for_env
    @required_files = []
    @found_files = []
    @result = {}
    @compose_file.each_service do |service|
      current_environment = []
      @environment[service.name] = {}
      if service.environment?
        if service.environment.instance_of?(Array)
          service.environment.each do |env|
            if env.include?('=')
              matches = env.to_enum(:scan, /(?<key>\w+)=(?<value>.*)/).map { Regexp.last_match }
              key, value = matches[:key], matches[:value]
              @environment[service.name][key] = {
                  name: key,
                  description: key,
                  default_value: value,
                  mandatory: 1,
                  basic: 1,
                  editable: 1,
                  type: 'env',
                  visible: 1
              }
              current_environment << "#{key}=<%= @#{service.name}_#{key.downcase} %>"
            else
              @environment[service.name][key] = {
                  name: key,
                  description: key,
                  default_value: '',
                  mandatory: 1,
                  basic: 1,
                  editable: 1,
                  type: 'env',
                  visible: 1
              }
              current_environment << "#{key}=<%= @#{service.name}_#{key.downcase} %>"
            end
          end
        elsif service.environment.instance_of?(Hash)
          service.environment.each do |key, val|
            @environment[service.name][key] = {
                name: key,
                description: key,
                default_value: val.nil? ? '' : val,
                mandatory: 1,
                basic: 1,
                editable: 1,
                type: 'env',
                visible: 1
            }
            current_environment << "#{key}=<%= @#{service.name}_#{key.downcase} %>"
          end
        end
      end
      if service.env_file?
        path = service.env_file.strip
        @required_files << path
        if path.start_with? '.'
          path.gsub!(/\A\.\/?/, '')
          path = "#{@repo_folder}/#{path}"
        end
        if File.file? path
          @found_files << @required_files.last
          File.foreach(path).with_index do |line,line_num|
            line.strip!
            next if line.start_with? '#' or line.empty?
            m = /(?<key>\w+)=(?<value>.+)/.match(line)
            key = m[:key]
            value = m[:value]
            @environment[service.name][key] = {
                name: key,
                description: key,
                default_value: value,
                mandatory: 1,
                basic: 1,
                editable: 1,
                type: 'env',
                visible: 1
            }
            current_environment << "#{key}=<%= @#{service.name}_#{key.downcase} %>"
          end
        end
      end
      service.environment = current_environment.clone
    end

    # DON'T NEED THIS ATM
    #
    # File.foreach(@compose_filepath).with_index do |line, line_num|
    #   line = line.gsub(/(\A|\s+)#.*/,'')
    #   matches = line.to_enum(:scan, /[^\$]\$(?<simple1>[A-Z]+)|[^\$]\${(?<simple2>[A-Z_]+)}|[^\$]\${(?<hard_k>[A-Z_]+):?-(?<hard_v>[^}]+)}/)
    #                 .map { Regexp.last_match }
    #   if matches
    #     matches.each do |match|
    #       puts 'MATCHES, 84 line'
    #       p match
    #       if match[:simple1]
    #         @environment << match[:simple1]
    #       end
    #       if match[:simple2]
    #         @environment << match[:simple2]
    #       end
    #       if match[:hard_k]
    #         @result[match[:hard_k]] = match[:hard_v]
    #       end
    #     end
    #   end
    # end


    if File.file? @env_file_path and !@required_files.include? '.env'
      @environment['_gex_shared'] = {}
      @required_files << '.env'
      @found_files << @required_files.last
      File.foreach(@env_file_path).with_index do |line,line_num|
        line.strip!
        next if line.start_with? '#' or line.empty?
        m = /(?<key>\w+)=(?<value>.+)/.match(line)
        @environment['_gex_shared'][m[:key]] = {
                description: m[:key],
                default_value: m[:value],
                mandatory: 1,
                basic: 1,
                editable: 1,
                type: 'env',
                visible: 1
            }
      end
    end
    puts @environment
    puts ' ----- FILES ------'
    puts 'REQUIRED ENV FILES', @required_files
    puts 'FOUND ENV FILES', @found_files
    puts 'DIFF', @required_files - @found_files
    puts ' ------------------'

    @environment.clone
  end

  def generate_docker_compose(path)
    compose = @compose_file.to_yaml
    @replacements.each_pair do |key, value|
      compose.gsub!(key,value)
    end
    File.open(path, 'w') do |f|
      f.puts compose
    end
  end

  def full_stack_shortcut(out_path)
    check_for_build
    check_for_env
    generate_docker_compose(out_path)
  end

end


class DockerCompose
  attr_accessor :services, :comments

  def initialize(compose_filepath)
    puts compose_filepath
    @yml = YAML.load_file(compose_filepath)
    @services = []
    if @yml['services']
      @yml['services'].each do |service|
        @services << Service.new(service)
      end
      @yml.delete('services')
    else
      @yml.each do |key, value|
        @services << Service.new([key,value])
      end
    end

    @comments = File.read(compose_filepath).scan(/^#.*?$/)
  end

  def each_service(&block)
    self.services.each(&block)
  end

  def method_missing(m, *args, &block)
    @yml[m.to_s]
  end

  def to_yaml
    output = ''
    @comments.each do |c|
      output << c
    end
    tmp_yml = @yml.clone
    tmp_yml['services'] = {}
    @services.each do |service|
      tmp_yml['services'][service.name] = service.to_hash
    end
    output << tmp_yml.to_yaml
    output.gsub!("---\n", '')
    output.gsub!(/(^\s*-\s+)/){|m| '  ' + m }
    output
  end
end

class Service

  attr_accessor :yml

  def initialize(yml)
    @yml = yml
    puts @yml
  end

  def name
    @yml[0]
  end

  def to_s
    @yml.to_s
  end

  def remove_build!
    @yml[1].delete('build')
  end

  def method_missing(m, *args, &block)
    method = m.to_s
    if method.end_with?('?')
      !@yml[1][method.gsub('?','')].nil?
    elsif method.end_with?('=')
      @yml[1][method.gsub('=','')] = args[0]
    else
      @yml[1][method]
    end
  end

  def to_hash
    @yml[1].clone
  end

end