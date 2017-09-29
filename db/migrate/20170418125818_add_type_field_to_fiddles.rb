class AddTypeFieldToFiddles < ActiveRecord::Migration
  def change
    add_column :fiddles, :code_type, :integer, default: 0
  end
end
