class AddPublicToken < ActiveRecord::Migration
  def up
    add_column :riddles, :public_token, :string
    add_index :riddles, :public_token
  end

  def down
    remove_column :riddles, :public_token
  end
end
