class CreateQuestions < ActiveRecord::Migration[8.1]
  def change
    create_table :questions do |t|
      t.references :quiz, null: false, foreign_key: true
      t.text :body, null: false
      t.integer :time_limit_seconds, null: false, default: 30
      t.integer :position, null: false

      t.timestamps
    end
  end
end
