require 'zlib'
require 'docker'
require 'fileutils'
require 'digest'
require 's3'

class DockerBuild

  class DockerBuildException < StandardError
    attr_accessor :included_exception
  end

  def initialize(hash)
    @result = DockerBuildResult.new
    @code = hash[:code]
    @token = hash[:token]
    @version = hash[:version].to_d
    @fiddle_version = Fiddle.for_token(@token).versions[@version]
    generate_path_to_folder
    @dockerfile_name = "Dockerfile_#{@version}"
  end


  def update_version(success)
    if @fiddle_version.nil?
      update_fiddle(success)
      return
    end
    hash = YAML.load(@fiddle_version.object)
    hash[:build_status] = success
    @fiddle_version.object = YAML.dump(hash)
    @fiddle_version.save
  end

  def update_fiddle(success)
    fiddle = Fiddle.for_token(@token)
    unless fiddle.nil?
      fiddle.update(:build_status => success)
    end
  end

  def build
    create_dockerfile

    begin
      @image = Docker::Image.build_from_dir(@path_to_folder,{ 'dockerfile' => @dockerfile_name })
      puts "Image = #{@image.json}"
    rescue => exc
      Rails.logger.error exc.inspect
      docker_exception = DockerBuildException.new
      docker_exception.included_exception = exc
      @result.exception = exc
      #binding.pry
      @result.success = 0
      update_version 0
      return @result
    ensure
      File.delete("#{@path_to_folder}/#{@dockerfile_name}")
    end

    @result.success = 1 unless @result.success == 3
    push_image
    update_version 1
    @result.pull = "docker pull #{Fiddle::REPO_ADDRESS}:#{@token}_#{@version.to_i}"
    @result
  end

  def push_image
    puts 'AUTH' if Docker.authenticate!(
                              'username' => ENV['DHUB_LOGIN'],
                              'password' => ENV['DHUB_PASSWD'],
                              'email' => ENV['DHUB_EMAIL']) #
    puts 'email' => ENV['DHUB_EMAIL'],
         'password' => ENV['DHUB_PASSWD'],
         'username' => ENV['DHUB_LOGIN']
    @image.tag('repo' => Fiddle::REPO_ADDRESS, 'tag' => "#{@token}_#{@version.to_i}", force: true)
    @image.push
  end


  def generate_path_to_folder
    @path_to_folder = "#{Rails.application.config.path_to_uploads}/#{@token}"
    FileUtils.mkdir_p(@path_to_folder) unless Dir.exist? @path_to_folder
  end

  def create_dockerfile
    path_to_dockerfile = "#{@path_to_folder}/#{@dockerfile_name}"
    File.open(path_to_dockerfile, 'w') do |f|
      f.puts(@code)
    end
  end

end

class DockerBuildResult
  attr_accessor :success, :exception, :pull

  def initialize(hash=nil)
    unless hash.nil?
      @success = hash[:success]
      @pull = hash[:pull] unless @success == 0
      @exception = hash[:exception]
    end

    #success : 0 - not successful; 1 - successfully built; 2 - same container was already built;
  end

end
