class AddUpdateFlagToFiddles < ActiveRecord::Migration
  def change
    add_column :fiddles, :update_flag, :int, default: 0
  end
end
