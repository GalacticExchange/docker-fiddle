class Upload < ActiveRecord::Base
  require 'fileutils'

  def self.copy_from_to(from, to) #from, to => public tokens of fiddles
    from = Upload.upload_path_for_token from
    to = Upload.upload_path_for_token to

    FileUtils.mkdir_p(to)
    FileUtils.cp_r "#{from}/.", to
  end

  def self.upload_path_for_token(token)
    "#{Rails.application.config.path_to_uploads}/#{token}"
  end

end
