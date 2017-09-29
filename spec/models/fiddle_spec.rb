require 'spec_helper'

describe Fiddle do
  describe 'new' do
    it 'should not create empty fiddle' do
      fiddle = Fiddle.new
      boolean = fiddle.save
      boolean.should eq(false)
    end
  end

end
