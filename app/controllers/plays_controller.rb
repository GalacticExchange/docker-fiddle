class PlaysController < ApplicationController
  respond_to :js, :only => :update, :layout => 'false'

  skip_before_action :verify_authenticity_token
  rescue_from DockerBuild::DockerBuildException, :with=> :error_fiddle_result
  respond_to :js


  def run
    #s = Redis::Semaphore.new(:docker_build, :resources => 5, :host => 'localhost')
    puts "PARAMS FOR RUN #{params}"
    code = params[:fiddle].fetch(:code)
    version = params[:fiddle_version]
    token = params[:fiddle_id]
    fiddle = Fiddle.for_token(token)
    fiddle.update(code: code)
    docker_build = DockerBuild.new(
        :code => code,
        :token => token,
        :version => version
    )
    # s.lock do
    #   puts "There are #{s.available_count} resources available right now."
       @fiddle_result = docker_build.build
    # end
  end


  protected
    def error_fiddle_result(exception)
      @execution_exception = exception
      render :run
    end


end
