class CreateReferences < ActiveRecord::Migration[8.1]
  def change
    create_table :references do |t|
      t.references :question, null: false, foreign_key: true
      t.string :url, null: false

      t.timestamps
    end
  end
end
