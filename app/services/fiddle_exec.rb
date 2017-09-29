require 'net/http'
require "active_support/all"
class FiddleExec
  class FiddleExecutionError < StandardError; end

  def initialize(base_url)

  end

  def execute(code)
    begin
      DockerBuild.new(code);
    rescue => exc
      Rails.logger.error exc.inspect
      raise FiddleExecutionError.new exc
    end
  end

  def transform_to_hash(result)
    json = ActiveSupport::JSON.decode(result)
    FiddleRun.new(json)
  end

end
