class AddBuildStatusToRiddles < ActiveRecord::Migration
  def change
    add_column :riddles, :build_status, :integer
  end
end
