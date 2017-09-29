require File.expand_path('../boot', __FILE__)

require 'rails/all'
Bundler.require(*Rails.groups)

module Rubyfiddle
  class Application < Rails::Application
    config.encoding = "utf-8"

    if Rails.env.development?
      config.path_to_uploads = '/home/iliya/uploads'
    else
      config.path_to_uploads = '/home/ubuntu/uploads'
    end

    # config.enable_dependency_loading = false
    # config.eager_load_paths += %W( #{config.root}/lib )

    config.autoload_paths += Dir["#{Rails.root}/lib/*"]

  end
end
