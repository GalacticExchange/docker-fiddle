require "active_support/all"
class FiddleRun
  attr_reader :output, :result, :exception
  def initialize(hash)
    @output = hash[:output]
    @result = hash[:result]
    @exception = hash[:exception]
  end
end
