class CreateUploads < ActiveRecord::Migration
  def change
    create_table :uploads do |t|
      t.string :token, :index
      t.timestamps
    end
  end
end
