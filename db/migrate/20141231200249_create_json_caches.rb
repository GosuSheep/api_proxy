class CreateJsonCaches < ActiveRecord::Migration
  def change
    create_table :json_caches do |t|
      t.string :url
      t.string :json

      t.timestamps null: false
    end
  end
end
