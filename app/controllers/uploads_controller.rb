class UploadsController < ApplicationController
  respond_to :js
  require 'zip'
  require 'json'
  require 'fileutils'

  def show_uploaded_files
    unless check_token(params['token'])
      render :json => {message: ['Wrong input data'], success: 0} and return
    end
    array = Dir["#{Upload.upload_path_for_token(params['token'])}/*"]
    if array.blank?
      render :json => {message: ['There are no files to display']} and return
    end
    array.map! {|x|
      size = File.size?(x)
      if size < 100
        size = "#{size} bytes"
      else
        size = "#{'%.2f' % (size/1024.0)} Kb"
      end
      x = {
        mime_type: File.mime_type(x),
        name: File.basename(x),
        size: size,
    }}
    render :json => {files: array}
  end

  def clear_files
    token = params['token']
    unless check_token(token)
      render :json => {message: ['Wrong input data'], success: 0} and return
    end
    array = Dir["#{Upload.upload_path_for_token(token)}/*"]
    if array.blank?
      render :json => {message: ['There are no files to delete'], success: 0} and return
    end
    begin
      FileUtils.rm_rf(array)
    rescue
      render :json => {message: ['There was an error deleting files'], success: 0} and return
    end

    render :json => {success: 1}
  end

  def check_token(token)
    if (token.length == 5) && (token =~ /[a-z0-9]{5}/)
      return Fiddle.for_token(token)
    else
      return false
    end
  end

  def create
    @result = {}
    @result[:success] = 1
    token = params[:fiddle_id]
    unless check_token(token)
      render :json => {message: ['Wrong input data'], success: 0} and return
    end
    path = Upload.upload_path_for_token(token)
    clean_before(path)
    uploaded_io = params[:upload][:file]
    if uploaded_io.size > 10.kilobytes
      render :json => {message: ['File is too big'], success: 0} and return
    end
    name = uploaded_io.original_filename

    Dir.mkdir(path) unless Dir.exist? path
    file_name = "#{path}/#{token}.zip"
    File.open(file_name, 'wb') do |file|
      file.write(uploaded_io.read)
    end
    unzip(file_name)
    clean_after(file_name)
    @result
  end


  private
    def unzip(file_name)
      Zip::File.open(file_name) do |zip_file|
        # Handle entries one by one
        zip_file.each do |entry|
          # Extract to file/directory/symlink
          #puts "Extracting #{entry.name}"
          entry.extract(file_name.gsub(/(\w*.zip)\z/,entry.name))
        end
      end
    end

    def clean_after(file_name)
      FileUtils.rm(file_name)
    end

    def clean_before(path)
      FileUtils.rm_rf("#{path}/.", secure: true)
    end

end
