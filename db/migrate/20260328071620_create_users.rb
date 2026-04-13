class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :token, null: false

      t.timestamps
    end

    add_index :users, :token, unique: true
  end
end
