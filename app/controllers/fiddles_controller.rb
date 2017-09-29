class FiddlesController < ApplicationController
  respond_to :html, :js
  rescue_from ActionController::RoutingError, :with => :not_found
  protect_from_forgery :except => [:index]

  def apphub
    if params[:type].blank? or params[:github_user].blank? or params[:url_path].blank?
      raise 'Wrong params'
    end
    @fiddle = ApphubAcc.get_fiddle(params)
    if @fiddle.instance_of?(Fiddle)
      render "fiddles/#{@fiddle.code_type}/index"
    else
      not_found
    end
  end

  def index
    case params[:code_type]
      when 'dockerfile'
        @fiddle = Fiddle.new(code_type: :dockerfile, code: '#This is a brand new dockerfile!')
        render 'fiddles/dockerfile/index'
      when 'compose'
        @fiddle = Fiddle.new(code_type: :compose, code: '#This is a brand new docker-compose file')
        render 'fiddles/compose/index'
      else
        render :index
    end
  end

  def new_dockerfile

  end

  def new_compose

  end

  def create
    @fiddle = Fiddle.create params.require(:fiddle).permit(:code, :code_type)
    puts @fiddle.code_type, @fiddle.public_token
    respond_with @fiddle
    # redirect_to versioned_fiddle_path(code_type: @fiddle.code_type, id: @fiddle.public_token, version: 1)
  end

  def update
    @fiddle = Fiddle.for_token(params[:id])
    @fiddle.update params.require(:fiddle).permit(:code)
    @fiddle.update(:build_status => 0)
    @fiddle.update(:update_flag => @fiddle.update_flag + 1)
    respond_with @fiddle
  end

  def fork
    @fiddle = Fiddle.for_token(params[:id]).fork!
    Upload.copy_from_to(params[:id], @fiddle.to_param) if @fiddle.code_type.eql? 'dockerfile'
    respond_with @fiddle
  end

  def show
    @param_id = params[:id]
    @param_code_type = params[:code_type]
    @param_version = params.fetch(:version, 1)
    @fiddle = get_version_of_fiddle(Fiddle.for_token(params[:id]), params.fetch(:version, 1))
    @fiddle_type = Fiddle.for_token(params[:id]).code_type
    puts @param_code_type
    puts @fiddle_type
    if !@param_code_type and @fiddle_type
      redirect_to versioned_fiddle_path(code_type: @fiddle_type, id: @param_id, version: @param_version) and return
    end
    if @fiddle.nil? or !@param_code_type.eql? @fiddle_type
      not_found
    else
      render "fiddles/#{@param_code_type}/index"
    end
  end

  def old_redirect
    @param_id = params[:id]
    @param_version = params.fetch(:version, 1)
    @fiddle = get_version_of_fiddle(Fiddle.for_token(params[:id]), params.fetch(:version, 1))
    if @fiddle.nil?
      not_found
    else
      puts 'HELL YES'
      redirect_to versioned_fiddle_path(code_type: Fiddle.for_token(params[:id]).code_type, id: @param_id, version: params[:version])
    end
  end
  
  def not_found
    render :file => "#{Rails.root}/public/404.html", :status => :not_found 
  end

  def get_version_of_fiddle(fiddle, version)
    version = Integer(version)
    available_count = fiddle.versions.length

    if available_count > version
      Maybe(fiddle.versions[version]).reify
    elsif version > available_count
      raise ActionController::RoutingError.new('Not Found')
    else
      fiddle
    end
  end
end
